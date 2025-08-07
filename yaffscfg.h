/*
 * YAFFS2 config, for littlefs benchmarking
 *
 */

#ifndef __YAFFSCFG_H__
#define __YAFFSCFG_H__


// yaffs2 includes
//
// note yaffs2 uses a lot of non-prefixed OS-level names
//
// we're using our current system's stdlib for these, but yaffs2 can be
// told to define its own if desired:
// - #define CONFIG_YAFFS_PROVIDE_DEFS 1
// - #define CONFIG_YAFFSFS_PROVIDE_VALUES 1
// - #define CONFIG_YAFFS_DEFINES_TYPES 1
//
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <stdint.h>

// needed only for constants?
#undef _FEATURES_H
#define _DEFAULT_SOURCE
#include <dirent.h>


// yaffs2 compile-time flags

#define CONFIG_YAFFS_DIRECT 1
#define CONFIG_YAFFS_YAFFS2 1
// TODO docs say not supported? TODO test this?
#define CONFIG_YAFFS_NO_YAFFS1 1
// well yes use less RAM
#define CONFIG_YAFFS_SMALL_RAM 1
#define CONFIG_YAFFS_USE_32_BIT_TIME_T 1
// TODO caches short names in RAM, test without this?
#define CONFIG_YAFFS_SHORT_NAMES_IN_RAM 1
// TODO enable trace for non-codemaps?
// disable trace for code size
#define CONFIG_YAFFS_NO_TRACE


// yaffs2 compile-time config

// number of statically allocated file handles
#define YAFFSFS_N_HANDLES 1
// number of statically allocated dirents for readdir
#define YAFFSFS_N_DSC 1


// various types
typedef uint64_t u64;
typedef uint32_t u32;
typedef uint16_t u16;
typedef uint8_t  u8;

typedef int64_t  s64;
typedef int32_t  s32;
typedef int16_t  s16;
typedef int8_t   s8;

typedef off_t loff_t;


#endif
