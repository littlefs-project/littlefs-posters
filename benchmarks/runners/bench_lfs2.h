/* littlefs2 integration functions
 */
#ifdef LFS2
#ifndef BENCH_LFS2_H
#define BENCH_LFS2_H

#include "lfs2.h"

// littlefs2 -> littlefs3 bd wrapper
int bench_lfs2_bd_read(const struct lfs2_config *cfg_lfs2,
        lfs2_block_t block, lfs2_off_t off,
        void *buffer, lfs2_size_t size);

int bench_lfs2_bd_prog(const struct lfs2_config *cfg_lfs2,
        lfs2_block_t block, lfs2_off_t off,
        const void *buffer, lfs2_size_t size);

int bench_lfs2_bd_erase(const struct lfs2_config *cfg_lfs2,
        lfs2_block_t block);

int bench_lfs2_bd_sync(const struct lfs2_config *cfg_lfs2);

#endif
#endif
