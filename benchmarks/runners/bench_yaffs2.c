/* yaffs2 integration functions
 */
#ifdef YAFFS2
#include "runners/bench_yaffs2.h"

// yaffs2 -> littlefs3 bd wrapper
int bench_yaffs2_bd_readchunk(struct yaffs_dev *yaffs2, int page,
        uint8_t *data, int data_len,
        uint8_t *oob, int oob_len,
        enum yaffs_ecc_result *ecc_result) {
    (void)oob;
    (void)oob_len;
    assert(oob_len == 0);

    const struct bench_cfg *cfg = yaffs2->driver_context;
    lfs3_block_t block = page / (BLOCK_SIZE / YPAGE_SIZE);
    lfs3_off_t off = (page % (BLOCK_SIZE / YPAGE_SIZE)) * YPAGE_SIZE;
    int err = bench_bd_read(&cfg->cfg, block, off, data, data_len);
    if (err) {
        return YAFFS_FAIL;
    }

    *ecc_result = YAFFS_ECC_RESULT_NO_ERROR;
    return YAFFS_OK;
}

int bench_yaffs2_bd_writechunk(struct yaffs_dev *yaffs2, int page,
        const uint8_t *data, int data_len,
        const uint8_t *oob, int oob_len) {
    (void)oob;
    (void)oob_len;
    assert(oob_len == 0);

    const struct bench_cfg *cfg = yaffs2->driver_context;
    lfs3_block_t block = page / (BLOCK_SIZE / YPAGE_SIZE);
    lfs3_off_t off = (page % (BLOCK_SIZE / YPAGE_SIZE)) * YPAGE_SIZE;
    int err = bench_bd_prog(&cfg->cfg, block, off, data, data_len);
    if (err) {
        return YAFFS_FAIL;
    }

    return YAFFS_OK;
}

int bench_yaffs2_bd_erase(struct yaffs_dev *yaffs2, int block) {
    const struct bench_cfg *cfg = yaffs2->driver_context;
    int err = bench_bd_erase(&cfg->cfg, block);
    if (err) {
        return YAFFS_FAIL;
    }

    return YAFFS_OK;
}

int bench_yaffs2_bd_markbad(struct yaffs_dev *yaffs2, int block) {
    (void)yaffs2;
    (void)block;
    // let's just assume this can't happen for now
    assert(false);
    __builtin_unreachable();
}

int bench_yaffs2_bd_checkbad(struct yaffs_dev *yaffs2, int block) {
    (void)yaffs2;
    (void)block;
    return YAFFS_OK;
}

#endif
