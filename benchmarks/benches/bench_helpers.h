/*
 * Some extra bench helpers
 *
 */
#ifndef BENCH_HELPERS_H
#define BENCH_HELPERS_H

#include "runners/bench_runner.h"


// warm up the filesystem
//
// this writes a 1 block file 2*block_count times to get it into a good
// state for benchmarking
//
// most importantly this uses up any pre-erased blocks created during
// format, which is inconsistent across filesystems and messes with
// benchmarks
int bench_helpers_warmup(const struct lfs3_cfg *cfg, void *fs);


// find tight disk usage
//
// this is going to be a bit different for each filesystem
//
uintmax_t bench_helpers_usage(const struct lfs3_cfg *cfg, void *fs);


#endif
