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
    // ok if we've read/progged more than twice the runtime we're
    // definitely stuck, note these aren't even the same units
    return (n > 2*bench_helpers_simtime(cfg));
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
    lfs3_soff_t free = yaffs_freespace("/");
    assert(free >= 0);

    // note used is already in bytes
    lfs3_soff_t used = (BLOCK_COUNT*BLOCK_SIZE) - free;
    return used;
    #endif
}


