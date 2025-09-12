/*
 * Some extra bench helpers
 *
 */
#ifndef BENCH_HELPERS_H
#define BENCH_HELPERS_H

#include "runners/bench_runner.h"


// get simulated time in nanoseconds since start of bench
//
// this is derived form the current read/prog/erase ops
uint64_t bench_helpers_simtime(const struct lfs3_cfg *cfg);

// reset the current time
//
// yes this just resets emubd's read/prog/erase trackers
void bench_helpers_simreset(const struct lfs3_cfg *cfg);

// is the current bench stuck? not making progress?
bool bench_helpers_simstuck(const struct lfs3_cfg *cfg, uint64_t n);


// warm up the filesystem
//
// this writes a 1 block file 2*block_count times to get it into a good
// state for benchmarking
//
// most importantly this uses up any pre-erased blocks created during
// format, which is inconsistent across filesystems and messes with
// benchmarks
int bench_helpers_warmup(const struct lfs3_cfg *cfg, void *fs);


// find disk usage
//
// this is a bit different for each filesystem
//
uintmax_t bench_helpers_usage(const struct lfs3_cfg *cfg, void *fs);


// find the bench stack usage
//
// in theory this is just the top level stack frame
//
// note the most important part of this is the noinline attribute,
// which forces a new stack frame
__attribute__((noinline))
size_t bench_helpers_bench_stack(void);


#endif
