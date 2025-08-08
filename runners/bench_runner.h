/*
 * Runner for littlefs benchmarks
 *
 * Copyright (c) 2022, The littlefs authors.
 * SPDX-License-Identifier: BSD-3-Clause
 */
#ifndef BENCH_RUNNER_H
#define BENCH_RUNNER_H


// override LFS3_TRACE
void bench_trace(const char *fmt, ...);

#define LFS3_TRACE_(fmt, ...) \
    bench_trace("%s:%d:trace: " fmt "%s\n", \
        __FILE__, \
        __LINE__, \
        __VA_ARGS__)
#define LFS3_TRACE(...) LFS3_TRACE_(__VA_ARGS__, "")
#define LFS2_TRACE(...) LFS3_TRACE_(__VA_ARGS__, "")
#define LFS3_EMUBD_TRACE(...) LFS3_TRACE_(__VA_ARGS__, "")
#define LFS2_EMUBD_TRACE(...) LFS3_TRACE_(__VA_ARGS__, "")

// note these are indirectly included in any generated files
#if defined(LFS3)
#include "lfs3.h"
#elif defined(LFS2)
#include "lfs2.h"
#elif defined(SPIFFS)
#include "spiffs.h"
#include "spiffs_nucleus.h"
#elif defined(YAFFS2)
#include "yaffs_yaffs2.h"
#include "yaffsfs.h"
#else
#error "No filesystem defined?"
#endif

// ifdef macros for filesystem version
#ifdef LFS3
#define BENCH_IFDEF_LFS3(a, b) (a)
#else
#define BENCH_IFDEF_LFS3(a, b) (b)
#endif
#ifdef LFS2
#define BENCH_IFDEF_LFS2(a, b) (b)
#else
#define BENCH_IFDEF_LFS2(a, b) (b)
#endif
#ifdef SPIFFS
#define BENCH_IFDEF_SPIFFS(a, b) (a)
#else
#define BENCH_IFDEF_SPIFFS(a, b) (b)
#endif
#ifdef YAFFS2
#define BENCH_IFDEF_YAFFS2(a, b) (a)
#else
#define BENCH_IFDEF_YAFFS2(a, b) (b)
#endif

#include "bd/lfs3_emubd.h"
#include <stdio.h>
#include <stdint.h>

// give source a chance to define feature macros
#undef _FEATURES_H
#undef _STDIO_H


// BENCH_START/BENCH_STOP macros measure readed/proged/erased bytes
// through emubd
void bench_start(const char *m, uintmax_t n);
void bench_stop(const char *m);

#define BENCH_START(m, n) bench_start(m, n)
#define BENCH_STOP(m) bench_stop(m)

// BENCH_RESULT/BENCH_FRESULT allow for explicit non-io measurements
void bench_result(const char *m, uintmax_t n, uintmax_t result);
void bench_fresult(const char *m, uintmax_t n, double result);

#define BENCH_RESULT(m, n, result) bench_result(m, n, result)
#define BENCH_FRESULT(m, n, result) bench_fresult(m, n, result)



// generated bench configurations
struct lfs3_cfg;

enum bench_flags {
    BENCH_INTERNAL  = 0x1,
};
typedef uint8_t bench_flags_t;

typedef struct bench_define {
    const char *name;
    intmax_t *define;
    intmax_t (*cb)(void *data, size_t i);
    void *data;
    size_t permutations;
} bench_define_t;

struct bench_case {
    const char *name;
    const char *path;
    bench_flags_t flags;

    const bench_define_t *defines;
    size_t permutations;

    bool (*if_)(void);
    void (*run)(struct lfs3_cfg *cfg);
};

struct bench_suite {
    const char *name;
    const char *path;
    bench_flags_t flags;

    const bench_define_t *defines;
    size_t define_count;

    const struct bench_case *cases;
    size_t case_count;
};

extern const struct bench_suite *const bench_suites[];
extern const size_t bench_suite_count;


// deterministic prng for pseudo-randomness in benches
uint32_t bench_prng(uint32_t *state);

#define BENCH_PRNG(state) bench_prng(state)

// generation of specific permutations of an array for exhaustive benching
size_t bench_factorial(size_t x);
void bench_permutation(size_t i, uint32_t *buffer, size_t size);

#define BENCH_FACTORIAL(x) bench_factorial(x)
#define BENCH_PERMUTATION(i, buffer, size) bench_permutation(i, buffer, size)




// a few preconfigured defines that control how benches run

// common implicit defines
#define BENCH_IMPLICIT_DEFINES \
    /*           name                value (overridable)                   */ \
    BENCH_DEFINE(READ_SIZE,          (PAGE_SIZE) ? PAGE_SIZE : 1            ) \
    BENCH_DEFINE(PROG_SIZE,          (PAGE_SIZE) ? PAGE_SIZE : 1            ) \
    BENCH_DEFINE(BLOCK_SIZE,         4096                                   ) \
    BENCH_DEFINE(DISK_SIZE,          8*1024*1024                            ) \
    BENCH_DEFINE(BLOCK_COUNT,        DISK_SIZE/BLOCK_SIZE                   ) \
    /* ERASE_SIZE is just informative                                      */ \
    BENCH_DEFINE(ERASE_SIZE,         4096                                   ) \
    /* simulated estimate timings in nanoseconds                           */ \
    /* these are derived from the w25q64jv datasheet, but should probably  */ \
    /* be overridden                                                       */ \
    BENCH_DEFINE(READ_TIME,          40                                     ) \
    BENCH_DEFINE(PROG_TIME,          1582                                   ) \
    BENCH_DEFINE(ERASE_TIME,         10986                                  ) \
    /* emubd config                                                        */ \
    BENCH_DEFINE(ERASE_VALUE,        -2                                     ) \
    BENCH_DEFINE(ERASE_CYCLES,       0                                      ) \
    BENCH_DEFINE(BADBLOCK_BEHAVIOR,  LFS3_EMUBD_BADBLOCK_PROGERROR          ) \
    BENCH_DEFINE(POWERLOSS_BEHAVIOR, LFS3_EMUBD_POWERLOSS_ATOMIC            ) \
    BENCH_DEFINE(EMUBD_SEED,         0                                      ) \
    /* filesystem-specific config                                          */ \
    BENCH_LFS3_DEFINES                                                        \
    BENCH_LFS2_DEFINES                                                        \
    BENCH_SPIFFS_DEFINES                                                      \
    BENCH_YAFFS2_DEFINES

// littlefs3 specific implicit defines
#ifdef LFS3
#define BENCH_LFS3_DEFINES \
    BENCH_DEFINE(FS,                 LFS3_IFDEF_BMAP(3, 30)                 ) \
    BENCH_DEFINE(PAGE_SIZE,          0                                      ) \
    BENCH_DEFINE(CACHE_SIZE,         0                                      ) \
    BENCH_DEFINE(BLOCK_RECYCLES,     1000                                   ) \
    /* NOTE this was expanded to 32 to match littlefs2, see v2's cfg       */ \
    BENCH_DEFINE(RCACHE_SIZE,        (CACHE_SIZE)                             \
                                        ? CACHE_SIZE                          \
                                        : LFS3_MAX(32, READ_SIZE)           ) \
    BENCH_DEFINE(PCACHE_SIZE,        (CACHE_SIZE)                             \
                                        ? CACHE_SIZE                          \
                                        : LFS3_MAX(32, PROG_SIZE)           ) \
    /* NOTE this max is not necessary, but levels the playing field        */ \
    /* vs littlefs v2 (was 16)                                             */ \
    BENCH_DEFINE(FILE_CACHE_SIZE,    (CACHE_SIZE)                             \
                                        ? CACHE_SIZE                          \
                                        : LFS3_MAX(                           \
                                            32,                               \
                                            LFS3_MAX(READ_SIZE, PROG_SIZE)) ) \
    BENCH_DEFINE(LOOKAHEAD_SIZE,     16                                     ) \
    BENCH_DEFINE(TREEDIFF_SIZE,      16                                     ) \
    BENCH_DEFINE(GC_FLAGS,           0                                      ) \
    BENCH_DEFINE(GC_STEPS,           0                                      ) \
    BENCH_DEFINE(GC_COMPACT_THRESH,  0                                      ) \
    BENCH_DEFINE(INLINE_SIZE,        BLOCK_SIZE/4                           ) \
    /* TODO crystal/fragment_thresh 1/16 or 1/8? */                           \
    BENCH_DEFINE(FRAGMENT_SIZE,      LFS3_MIN(BLOCK_SIZE/16, 512)           ) \
    /* TODO should max-prog_size be enforced in lfs3_init? */                 \
    BENCH_DEFINE(CRYSTAL_THRESH,     LFS3_MAX(BLOCK_SIZE/16, PROG_SIZE)     ) \
    BENCH_DEFINE(BMAP_SCAN_THRESH,   BLOCK_COUNT/4                          )
#else
#define BENCH_LFS3_DEFINES
#endif

// littlefs2 specific implicit defines
#ifdef LFS2
#define BENCH_LFS2_DEFINES \
    /*           name                value (overridable)                   */ \
    BENCH_DEFINE(FS,                 2                                      ) \
    BENCH_DEFINE(PAGE_SIZE,          0                                      ) \
    BENCH_DEFINE(BLOCK_CYCLES,       1000                                   ) \
    /* NOTE this is necessary for inline files to not explode in           */ \
    /* many testing                                                        */ \
    BENCH_DEFINE(CACHE_SIZE,         LFS3_MAX(                                \
                                        32,                                   \
                                        LFS3_MAX(READ_SIZE, PROG_SIZE))     ) \
    BENCH_DEFINE(LOOKAHEAD_SIZE,     16                                     ) \
    BENCH_DEFINE(COMPACT_THRESH,     0                                      ) \
    BENCH_DEFINE(METADATA_MAX,       0                                      ) \
    BENCH_DEFINE(INLINE_MAX,         0                                      )
#else
#define BENCH_LFS2_DEFINES
#endif

// spiffs specific defines
#ifdef SPIFFS
#define BENCH_SPIFFS_DEFINES \
    /*           name                value (overridable)                   */ \
    BENCH_DEFINE(FS,                 4                                      ) \
    BENCH_DEFINE(PAGE_SIZE,          LFS3_MAX(PROG_SIZE, 256)               ) \
    BENCH_DEFINE(FD_COUNT,           1                                      ) \
    BENCH_DEFINE(FD_SIZE,            FD_COUNT*sizeof(spiffs_fd)             ) \
    BENCH_DEFINE(CACHE_SIZE,         0                                      ) \
    /* spiffs's page cache is different from littlefs's cache,             */ \
    /* let's default to 2 pages, and add CACHE_SIZE if explicitly set      */ \
    BENCH_DEFINE(PAGECACHE_COUNT,    2                                      ) \
    BENCH_DEFINE(PAGECACHE_SIZE,     sizeof(spiffs_cache)                     \
                                        + PAGECACHE_COUNT                     \
                                            * (sizeof(spiffs_cache_page)      \
                                            + PAGE_SIZE)                      \
                                        + CACHE_SIZE)
#else
#define BENCH_SPIFFS_DEFINES
#endif

// yaffs2 specific implicit defines
#ifdef YAFFS2
#define BENCH_YAFFS2_DEFINES \
    /*           name                value (overridable)                   */ \
    BENCH_DEFINE(FS,                 5                                      ) \
    /* this is limited by struct yaffs_obj_hdr                             */ \
    BENCH_DEFINE(PAGE_SIZE,          LFS3_MAX(PROG_SIZE, 512)               ) \
    BENCH_DEFINE(CACHE_SIZE,         0                                      ) \
    BENCH_DEFINE(RESERVED_BLOCKS,    5                                      ) \
    /* yaffs2's page cache is different from littlefs's cache,             */ \
    /* let's default to 2 pages, and add CACHE_SIZE if explicitly set      */ \
    BENCH_DEFINE(PAGECACHE_COUNT,    2 + (CACHE_SIZE / PAGE_SIZE)           ) \
    BENCH_DEFINE(REFRESH_PERIOD,     1000                                   )
#else
#define BENCH_YAFFS2_DEFINES
#endif

// declare defines as global intmax_ts
#define BENCH_DEFINE(k, v) extern intmax_t k;
BENCH_IMPLICIT_DEFINES
#undef BENCH_DEFINE



// this gets a bit messy due to littlefs's bds expecting a littlefs
// lfs3_cfg struct
//
// to make this work with other filesystems, we always wrap an lfs3_cfg
// and do some funky casting to get to the filesystem-specific config
//
// this is a big hack and should _never_ be included in stack/ctx
// measurements
struct bench_cfg {
    struct lfs3_cfg cfg;
    #if defined(LFS2)
    struct lfs2_config cfg_lfs2;
    #elif defined(SPIFFS)
    spiffs_config cfg_spiffs;
    #elif defined(YAFFS2)
    struct {
        struct yaffs_param param;
        struct yaffs_driver drv;
    } cfg_yaffs2;
    #endif
};

// bench.py generates CFG as a lfs3_cfg pointers, these are conveniences
// to access filesystem-specific cfg
#define CFG_LFS3 CFG
#define CFG_LFS2 (&((const struct bench_cfg*)CFG)->cfg_lfs2)
#define CFG_SPIFFS (&((const struct bench_cfg*)CFG)->cfg_spiffs)
#define CFG_YAFFS2 (&((const struct bench_cfg*)CFG)->cfg_yaffs2)

// map defines to cfg struct fields

// common cfg struct fields
#define BENCH_CFG \
    .read_size          = READ_SIZE,            \
    .prog_size          = PROG_SIZE,            \
    .block_size         = BLOCK_SIZE,           \
    .block_count        = BLOCK_COUNT,

// common bd cfg struct fields
#define BENCH_BDCFG \
    .erase_value        = ERASE_VALUE,          \
    .erase_cycles       = ERASE_CYCLES,         \
    .badblock_behavior  = BADBLOCK_BEHAVIOR,    \
    .powerloss_behavior = POWERLOSS_BEHAVIOR,   \
    .seed               = EMUBD_SEED,

// filesystem-specific cfg struct fields

// littlefs3 cfg struct fields
#ifdef LFS3
#define BENCH_LFS3_CFG \
    .block_recycles     = BLOCK_RECYCLES,       \
    .rcache_size        = RCACHE_SIZE,          \
    .pcache_size        = PCACHE_SIZE,          \
    .file_cache_size    = FILE_CACHE_SIZE,      \
    .lookahead_size     = LOOKAHEAD_SIZE,       \
    BENCH_BMAP_CFG                              \
    BENCH_GC_CFG                                \
    .gc_compact_thresh  = GC_COMPACT_THRESH,    \
    .inline_size        = INLINE_SIZE,          \
    .fragment_size      = FRAGMENT_SIZE,        \
    .crystal_thresh     = CRYSTAL_THRESH,

#ifdef LFS3_BMAP
#define BENCH_BMAP_CFG \
    .treediff_size      = TREEDIFF_SIZE,        \
    .bmap_scan_thresh   = BMAP_SCAN_THRESH,
#else
#define BENCH_BMAP_CFG
#endif

#ifdef LFS3_GC
#define BENCH_GC_CFG \
    .gc_flags           = GC_FLAGS,             \
    .gc_steps           = GC_STEPS,
#else
#define BENCH_GC_CFG
#endif
#endif

// littlefs2 cfg struct fields
#ifdef LFS2
#define BENCH_LFS2_CFG \
    .read_size          = READ_SIZE,            \
    .prog_size          = PROG_SIZE,            \
    .block_size         = BLOCK_SIZE,           \
    .block_count        = BLOCK_COUNT,          \
    .block_cycles       = BLOCK_CYCLES,         \
    .cache_size         = CACHE_SIZE,           \
    .lookahead_size     = LOOKAHEAD_SIZE,       \
    .compact_thresh     = COMPACT_THRESH,       \
    .metadata_max       = METADATA_MAX,         \
    .inline_max         = INLINE_MAX,
#endif

// spiffs cfg struct fields
#ifdef SPIFFS
#define BENCH_SPIFFS_CFG \
    .phys_size          = BLOCK_SIZE * BLOCK_COUNT, \
    .phys_addr          = 0,                        \
    .phys_erase_block   = BLOCK_SIZE,               \
    .log_block_size     = BLOCK_SIZE,               \
    .log_page_size      = PAGE_SIZE,
#endif

// yaffs2 cfg struct fields
#ifdef YAFFS2
#define BENCH_YAFFS2_CFG \
    .name                   = "/",                      \
    .inband_tags            = true,                     \
    .total_bytes_per_chunk  = PAGE_SIZE,                \
    .chunks_per_block       = BLOCK_SIZE / PAGE_SIZE,   \
    .spare_bytes_per_chunk  = 0,                        \
    .start_block            = 0,                        \
    .end_block              = BLOCK_COUNT-1,            \
    .n_reserved_blocks      = RESERVED_BLOCKS,          \
    .n_caches               = PAGECACHE_COUNT,          \
    .cache_bypass_aligned   = false,                    \
    .use_nand_ecc           = true, /* fake ecc */      \
    .tags_9bytes            = false,                    \
    .no_tags_ecc            = false,                    \
    .is_yaffs2              = true,                     \
    .empty_lost_n_found     = false,                    \
    .refresh_period         = REFRESH_PERIOD,           \
    .skip_checkpt_rd        = false,                    \
    .skip_checkpt_wr        = false,                    \
    .enable_xattr           = false,                    \
    .max_objects            = 0, /* unbounded */        \
    .hide_lost_n_found      = false,                    \
    .stored_endian          = 1, /* le */
#endif


#endif
