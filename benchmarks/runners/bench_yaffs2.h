/* yaffs2 integration functions
 */
#ifdef YAFFS2
#ifndef BENCH_YAFFS2_H
#define BENCH_YAFFS2_H

#include "yaffs_yaffs2.h"
#include "yaffsfs.h"

// yaffs2 -> littlefs3 bd wrapper
int bench_yaffs2_bd_readchunk(struct yaffs_dev *yaffs2, int page,
        uint8_t *data, int data_len,
        uint8_t *oob, int oob_len,
        enum yaffs_ecc_result *ecc_result);

int bench_yaffs2_bd_writechunk(struct yaffs_dev *yaffs2, int page,
        const uint8_t *data, int data_len,
        const uint8_t *oob, int oob_len);

int bench_yaffs2_bd_erase(struct yaffs_dev *yaffs2, int block);

int bench_yaffs2_bd_markbad(struct yaffs_dev *yaffs2, int block);

int bench_yaffs2_bd_checkbad(struct yaffs_dev *yaffs2, int block);

#endif
#endif
