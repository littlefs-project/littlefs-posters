/* spiffs integration functions
 */
#ifdef SPIFFS
#include "runners/bench_spiffs.h"

// try to minimize buffer allocation cost
static uint8_t *bench_spiffs_bd_buffer = NULL;
static uint8_t *bench_spiffs_bd_buffer_size = 0;

// spiffs -> littlefs3 bd wrapper
s32_t bench_spiffs_bd_read(struct spiffs_t *spiffs,
        u32_t addr, u32_t size, u8_t *dst) {
    const struct bench_cfg *cfg = spiffs->user_data;
    lfs3_block_t block = addr / cfg->cfg.block_size;
    lfs3_size_t off = addr % cfg->cfg.block_size;
    // spiffs expect byte reads, so we may need to read into a buffer
    if (cfg->cfg.read_size == 1) {
        return bench_bd_read(&cfg->cfg, block, off, dst, size);
    } else {
        // bit of a hack here to cache the allocated buffer without
        // breaking our heap measurements
        BENCH_HEAP_INC(cfg->cfg.read_size);
        if (cfg->cfg.read_size > bench_spiffs_bd_buffer_size) {
            BENCH_HEAP_PAUSE();
            free(bench_spiffs_bd_buffer);
            bench_spiffs_bd_buffer = malloc(cfg->cfg.read_size);
            BENCH_HEAP_RESUME();
        }

        while (size > 0) {
            lfs3_size_t aligned_off = lfs3_aligndown(off, cfg->cfg.read_size);
            lfs3_ssize_t d = lfs3_min(
                    size,
                    cfg->cfg.read_size - (off - aligned_off));

            int err = bench_bd_read(&cfg->cfg, block, aligned_off,
                    bench_spiffs_bd_buffer, cfg->cfg.read_size);
            if (err) {
                BENCH_HEAP_DEC(cfg->cfg.read_size);
                return err;
            }

            memcpy(dst, bench_spiffs_bd_buffer + (off - aligned_off), d);
            dst += d;
            size -= d;
            off += d;
        }

        BENCH_HEAP_DEC(cfg->cfg.read_size);
        return 0;
    }
}

s32_t bench_spiffs_bd_write(struct spiffs_t *spiffs,
        u32_t addr, u32_t size, u8_t *src) {
    const struct bench_cfg *cfg = spiffs->user_data;
    lfs3_block_t block = addr / cfg->cfg.block_size;
    lfs3_size_t off = addr % cfg->cfg.block_size;
    // spiffs expect byte reads, so we may need to read into a buffer
    if (cfg->cfg.prog_size == 1) {
        return bench_bd_prog(&cfg->cfg, block, off, src, size);
    } else {
        // bit of a hack here to cache the allocated buffer without
        // breaking our heap measurements
        BENCH_HEAP_INC(cfg->cfg.prog_size);
        if (cfg->cfg.prog_size > bench_spiffs_bd_buffer_size) {
            BENCH_HEAP_PAUSE();
            free(bench_spiffs_bd_buffer);
            bench_spiffs_bd_buffer = malloc(cfg->cfg.prog_size);
            BENCH_HEAP_RESUME();
        }

        while (size > 0) {
            lfs3_size_t aligned_off = lfs3_aligndown(off, cfg->cfg.prog_size);
            lfs3_ssize_t d = lfs3_min(
                    size,
                    cfg->cfg.prog_size - (off - aligned_off));
            memset(bench_spiffs_bd_buffer, 0xff, cfg->cfg.prog_size);
            memcpy(bench_spiffs_bd_buffer + (off - aligned_off), src, d);

            int err = bench_bd_prog(&cfg->cfg, block, aligned_off,
                    bench_spiffs_bd_buffer, cfg->cfg.prog_size);
            if (err) {
                BENCH_HEAP_DEC(cfg->cfg.prog_size);
                return err;
            }

            src += d;
            size -= d;
            off += d;
        }

        BENCH_HEAP_DEC(cfg->cfg.prog_size);
        return 0;
    }
}

s32_t bench_spiffs_bd_erase(struct spiffs_t *spiffs,
        u32_t addr, u32_t size) {
    const struct bench_cfg *cfg = spiffs->user_data;
    lfs3_block_t block = addr / cfg->cfg.block_size;
    lfs3_size_t off = addr % cfg->cfg.block_size;
    // off should always be zero
    assert(off == 0);
    // we expect block size here?
    assert(size == cfg->cfg.block_size);
    return bench_bd_erase(&cfg->cfg, block);
}

#endif
