/* spiffs integration functions
 */
#ifdef SPIFFS
#ifndef BENCH_SPIFFS_H
#define BENCH_SPIFFS_H

#include "spiffs.h"
#include "spiffs_nucleus.h"

// spiffs -> littlefs3 bd wrapper
s32_t bench_spiffs_bd_read(struct spiffs_t *spiffs,
        u32_t addr, u32_t size, u8_t *dst);

s32_t bench_spiffs_bd_write(struct spiffs_t *spiffs,
        u32_t addr, u32_t size, u8_t *src);

s32_t bench_spiffs_bd_erase(struct spiffs_t *spiffs,
        u32_t addr, u32_t size);

#endif
#endif
