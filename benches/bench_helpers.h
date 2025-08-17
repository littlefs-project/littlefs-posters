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
void bench_helpers_clobber(const struct lfs3_cfg *cfg);


// find disk usage
//
// this is a bit different for each filesystem
//
uintmax_t bench_helpers_usage(void *fs);



#endif
