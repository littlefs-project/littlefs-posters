/*
 * Some extra bench helpers
 *
 */

#include "benches/bench_helpers.h"



// get simulated time in nanoseconds since start of bench
//
// this is derived form the current read/prog/erase ops
uint64_t bench_helpers_simtime(const struct lfs3_cfg *cfg) {
    uint64_t time = 0;
    #ifdef BENCH_KIWIBD
    time += lfs3_kiwibd_readed(cfg) * READ_TIME;
    time += lfs3_kiwibd_proged(cfg) * PROG_TIME;
    time += lfs3_kiwibd_erased(cfg) * ERASE_TIME;
    #else
    time += lfs3_emubd_readed(cfg) * READ_TIME;
    time += lfs3_emubd_proged(cfg) * PROG_TIME;
    time += lfs3_emubd_erased(cfg) * ERASE_TIME;
    #endif
    return time;
}

// reset the current time
//
// yes this just resets emubd/kiwibd's read/prog/erase trackers
void bench_helpers_simreset(const struct lfs3_cfg *cfg) {
    #ifdef BENCH_KIWIBD
    lfs3_kiwibd_setreaded(cfg, 0);
    lfs3_kiwibd_setproged(cfg, 0);
    lfs3_kiwibd_seterased(cfg, 0);
    #else
    lfs3_emubd_setreaded(cfg, 0);
    lfs3_emubd_setproged(cfg, 0);
    lfs3_emubd_seterased(cfg, 0);
    #endif
}

// is the current bench stuck? not making progress?
bool bench_helpers_simstuck(const struct lfs3_cfg *cfg, uint64_t n) {
    // ok if we've read/progged more than 4x the runtime we're
    // definitely stuck, note these aren't even the same units
    return (n > 4*bench_helpers_simtime(cfg));
}



// clobber disk such that the filesystem thinks all blocks are unerased
//
// spiffs and yaffs2 assume a full disk erase during format, but this
// hides erase costs on large disks, clobbering levels the playing field
// a bit
//
// eventually littlefs3 will also support persistent erased-state
// tracking, but we may want to clobber during benchmarking to avoid
// weird performance biases on the first pass through disk
//
void bench_helpers_clobber(const struct lfs3_cfg *cfg) {
    #if defined(LFS3)
    // do nothing, littlefs3 currently assumes unerased after format
    (void)cfg;
    #elif defined(LFS2)
    // do nothing, littlefs2 currently assumes unerased after format
    (void)cfg;
    #elif defined(SPIFFS)
    // zeroing everything clears spiffs's lookup tables and makes it think
    // all pages have been deleted
    //
    // leave first three blocks erased to be fair
    extern void bench_heap_pause(void);
    bench_heap_pause();
    uint8_t *buffer = malloc(BLOCK_SIZE);
    memset(buffer, 0, BLOCK_SIZE);
    for (lfs3_block_t i = 2; i < BLOCK_COUNT; i++) {
        cfg->erase(cfg, i) => 0;
        cfg->prog(cfg, i, 0, buffer, BLOCK_SIZE) => 0;
    }
    free(buffer);
    extern void bench_heap_resume(void);
    bench_heap_resume();
    #elif defined(YAFFS2)
    // for yaffs we have to be a bit more clever
    //
    // instead of zeroing, fill pages with redundant unused data, this
    // matches the yaffs_packed_tags2_tags_only struct that gets written
    // to the end of each page:
    // - seq_number = 0x1001 (must be >=0x00001000,<=0xefffff00!)
    //   (YAFFS_LOWEST_SEQUENCE_NUMBER, YAFFS_HIGHEST_SEQUENCE_NUMBER)
    // - obj_id = 1
    // - chunk_id = 1
    // - n_bytes 0
    //
    // I think this might still end up with one data page that never gets
    // fully gced, but that shouldn't interfere with our benchmarks
    //
    // leave first three blocks erased to be fair
    extern void bench_heap_pause(void);
    bench_heap_pause();
    uint8_t *buffer = malloc(BLOCK_SIZE);
    memset(buffer, 0, BLOCK_SIZE);
    for (lfs3_size_t i = 0; i < BLOCK_SIZE / YPAGE_SIZE; i++) {
        buffer[i*YPAGE_SIZE+YPAGE_SIZE-16+0]  = 0x01;
        buffer[i*YPAGE_SIZE+YPAGE_SIZE-16+1]  = 0x10;
        buffer[i*YPAGE_SIZE+YPAGE_SIZE-16+2]  = 0;
        buffer[i*YPAGE_SIZE+YPAGE_SIZE-16+3]  = 0;

        buffer[i*YPAGE_SIZE+YPAGE_SIZE-16+4]  = 0x01;
        buffer[i*YPAGE_SIZE+YPAGE_SIZE-16+5]  = 0;
        buffer[i*YPAGE_SIZE+YPAGE_SIZE-16+6]  = 0;
        buffer[i*YPAGE_SIZE+YPAGE_SIZE-16+7]  = 0;

        buffer[i*YPAGE_SIZE+YPAGE_SIZE-16+8]  = 0x01;
        buffer[i*YPAGE_SIZE+YPAGE_SIZE-16+9]  = 0;
        buffer[i*YPAGE_SIZE+YPAGE_SIZE-16+10] = 0;
        buffer[i*YPAGE_SIZE+YPAGE_SIZE-16+11] = 0;

        buffer[i*YPAGE_SIZE+YPAGE_SIZE-16+12] = 0;
        buffer[i*YPAGE_SIZE+YPAGE_SIZE-16+13] = 0;
        buffer[i*YPAGE_SIZE+YPAGE_SIZE-16+14] = 0;
        buffer[i*YPAGE_SIZE+YPAGE_SIZE-16+15] = 0;
    }
    for (lfs3_block_t i = 2; i < BLOCK_COUNT; i++) {
        cfg->erase(cfg, i) => 0;
        cfg->prog(cfg, i, 0, buffer, BLOCK_SIZE) => 0;
    }
    free(buffer);
    extern void bench_heap_resume(void);
    bench_heap_resume();
    #endif
}



// needed to find disk usage for littlefs2
#if defined(LFS2)
static int bench_helpers_usage_cb(void *ctx, lfs3_block_t block) {
    uint8_t *usage_bmap = ctx;
    // TODO found a bug in littlefs2? lfs2_fs_traverse is returning the
    // fake cache block when it shouldn't
    if ((lfs3_sblock_t)block < 0) {
        LFS3_WARN("lfs2_fs_traverse: weird block? %d", block);
        return 0;
    }
    usage_bmap[block/8] |= 1 << (block % 8);
    return 0;
}
#endif

// find disk usage
//
// this is a bit different for each filesystem
//
uintmax_t bench_helpers_usage(void *fs) {
    #if defined(LFS3)
    lfs3_t *lfs3 = fs;
    // measure disk usage
    //
    // littlefs can be a dag, so build a bitmap to find the exact
    // disk usage
    uint8_t *usage_bmap = malloc((BLOCK_COUNT+8-1)/8);
    memset(usage_bmap, 0, (BLOCK_COUNT+8-1)/8);

    lfs3_trv_t trv;
    lfs3_trv_open(lfs3, &trv, 0) => 0;
    while (true) {
        struct lfs3_tinfo tinfo;
        int err = lfs3_trv_read(lfs3, &trv, &tinfo);
        assert(!err || err == LFS3_ERR_NOENT);
        if (err == LFS3_ERR_NOENT) {
            break;
        }

        usage_bmap[tinfo.block/8] |= 1 << (tinfo.block % 8);
    }
    lfs3_trv_close(lfs3, &trv) => 0;

    lfs3_size_t usage = 0;
    for (lfs3_size_t j = 0; j < BLOCK_COUNT; j++) {
        if (usage_bmap[j / 8] & (1 << (j % 8))) {
            usage += 1;
        }
    }

    free(usage_bmap);
    return (uintmax_t)usage * (uintmax_t)BLOCK_SIZE;

    #elif defined(LFS2)
    lfs2_t *lfs2 = fs;
    // measure disk usage
    //
    // littlefs can be a dag, so build a bitmap to find the exact
    // disk usage
    uint8_t *usage_bmap = malloc((BLOCK_COUNT+8-1)/8);
    memset(usage_bmap, 0, (BLOCK_COUNT+8-1)/8);

    int err = lfs2_fs_traverse(lfs2, bench_helpers_usage_cb, usage_bmap);
    if (err) {
        LFS3_WARN("lfs2_fs_traverse: failed %d", err);
    }

    lfs3_size_t usage = 0;
    for (lfs3_size_t j = 0; j < BLOCK_COUNT; j++) {
        if (usage_bmap[j / 8] & (1 << (j % 8))) {
            usage += 1;
        }
    }

    free(usage_bmap);
    return (uintmax_t)usage * (uintmax_t)BLOCK_SIZE;

    #elif defined(SPIFFS)
    spiffs *spiffs = fs;
    // measure disk usage
    //
    // we rely on spiffs's internal bookkeeping here
    u32_t total;
    u32_t used;
    SPIFFS_info(spiffs, &total, &used) => 0;

    // include metadata pages in used
    used += (BLOCK_COUNT*BLOCK_SIZE) - total;

    // note used is already in bytes
    return used;

    #elif defined(YAFFS2)
    (void)fs;
    // measure disk usage
    //
    // we rely on yaffs2's internal bookkeeping here
    //
    // watch out for integer overflow!
    loff_t free = yaffs_freespace("/");
    assert(free >= 0);

    // note used is already in bytes
    loff_t used = (BLOCK_COUNT*BLOCK_SIZE) - free;
    return used;
    #endif
}


