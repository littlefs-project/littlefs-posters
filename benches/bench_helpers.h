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


// find disk usage
//
// this is a bit different for each filesystem
//
uintmax_t bench_helpers_usage(void *fs);



#endif
