/* littlefs2 integration functions
 */
#ifdef LFS2
#include "runners/bench_lfs2.h"

// littlefs2 -> littlefs3 bd wrapper
int bench_lfs2_bd_read(const struct lfs2_config *cfg_lfs2,
        lfs2_block_t block, lfs2_off_t off,
        void *buffer, lfs2_size_t size) {
    const struct bench_cfg *cfg = BENCH_CFG_FROM(cfg_lfs2, cfg_lfs2);
    return cfg->cfg.read(&cfg->cfg, block, off, buffer, size);
}

int bench_lfs2_bd_prog(const struct lfs2_config *cfg_lfs2,
        lfs2_block_t block, lfs2_off_t off,
        const void *buffer, lfs2_size_t size) {
    const struct bench_cfg *cfg = BENCH_CFG_FROM(cfg_lfs2, cfg_lfs2);
    return cfg->cfg.prog(&cfg->cfg, block, off, buffer, size);
}

int bench_lfs2_bd_erase(const struct lfs2_config *cfg_lfs2,
        lfs2_block_t block) {
    const struct bench_cfg *cfg = BENCH_CFG_FROM(cfg_lfs2, cfg_lfs2);
    return cfg->cfg.erase(&cfg->cfg, block);
}

int bench_lfs2_bd_sync(const struct lfs2_config *cfg_lfs2) {
    const struct bench_cfg *cfg = BENCH_CFG_FROM(cfg_lfs2, cfg_lfs2);
    return cfg->cfg.sync(&cfg->cfg);
}

#endif
