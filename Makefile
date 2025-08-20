# overrideable build dir, default to ./build
BUILDDIR ?= build
# overrideable codemaps dir, defaults to ./codemaps
CODEMAPSDIR ?= codemaps
# overrideable results dir, default to ./results
RESULTSDIR ?= results
# overrideable plots dir, defaults ./plots
PLOTSDIR ?= plots
# overrideable tikz dir, defaults to ./tikz
TIKZDIR ?= tikz


# overall disk size?
DISK_SIZE ?= 8388608

# size to test for litmus testing?
P26_LITMUS_SIZE ?= 32768
# chunks size, i.e. size of writes/reads, for litmus testing?
P26_LITMUS_CHUNK ?= 32
# step size for litmus testing?
ifdef PRECISE
P26_LITMUS_STEP ?= 1
else
P26_LITMUS_STEP ?= 8 # was 1, prioritizing speed over accuracy
endif
# how many samples to measure for litmus testing?
ifdef PRECISE
P26_LITMUS_SAMPLES ?= 16
else
P26_LITMUS_SAMPLES ?= 4
endif

# range of sizes to test for throughput testing?
P26_T_SIZES ?= 1024,2048,4096,8192,16384,32768
# default size for throughput testing?
P26_T_SIZE ?= $(lastword $(subst $(,), ,$(P26_T_SIZES)))
# chunks size, i.e. size of writes/reads, for throughput testing?
P26_T_CHUNK ?= 32
# simulation time in nanoseconds for throughput testing?
ifndef P26_T_SIM_TIME
ifndef P26_T_SIM_SIZE
ifdef PRECISE
P26_T_SIM_TIME ?= 600000000000 # 10 minutes
else
P26_T_SIM_TIME ?= 60000000000 # 1 minute
endif
endif
endif


# configurations that simulate real-world storage
#
# with *_TIME indicating a per-byte estimate in nanoseconds
#
# Using a per-byte estimate isn't _super_ accurate, it ignores
# important nuances such as instruction overhead and on-disk buffers/
# caches that make batched reads/progs more efficient. But it's simple,
# and provides a decent rough estimate.
#

# sd/emmc - estimated based on w25n01gv, assumes a _perfect_ FTL
#
# these estimates are at the byte-level, so the block size doesn't
# actual change anything
#
EMMC_READ_SIZE  ?= 512
EMMC_PROG_SIZE  ?= 512
EMMC_ERASE_SIZE ?= 512
# TODO does it make sense to shrink the non-bmap's block size?
EMMC_LFS3_BLOCK_SIZE ?= 1024 # v3 performs better with larger block sizes
EMMC_LFS3NB_BLOCK_SIZE ?= 1024
EMMC_LFS2_BLOCK_SIZE ?= 512  # but no reason to penalize v2
EMMC_SPIFFS_BLOCK_SIZE ?= 1024
EMMC_YAFFS2_BLOCK_SIZE ?= 1024
EMMC_READ_TIME  ?= 31   # taken from w25n01gv, read time
EMMC_PROG_TIME  ?= 156  # taken from w25n01gv, prog time + erase time
EMMC_ERASE_TIME ?= 0    # noop

# nor flash - based on w25q64jv
#
# https://www.winbond.com/resource-files/W25Q256JV%20SPI%20RevQ%2002072025%20Plus.pdf
#
# FR=104 MHz, quad prog (9.6 ns * 8/4)
# => +~19 ns for bus (not read!)
#
NOR_READ_SIZE  ?= 1
NOR_PROG_SIZE  ?= 1
NOR_ERASE_SIZE ?= 4096
NOR_LFS3_BLOCK_SIZE ?= 4096
NOR_LFS3NB_BLOCK_SIZE ?= 4096
NOR_LFS2_BLOCK_SIZE ?= 4096
NOR_SPIFFS_BLOCK_SIZE ?= 4096
NOR_YAFFS2_BLOCK_SIZE ?= 4096
NOR_READ_TIME  ?= 40    # fR=50 MHz, quad read (20 ns * 8/4)
NOR_PROG_TIME  ?= 1582  # tPP=0.4 ms, page=256 (0.4 ms / 256 + bus)
NOR_ERASE_TIME ?= 10986 # tSE=45 ms, sector=4096 (45 ms / 4096)

# nand flash - based on w25n01gv
#
# https://www.winbond.com/resource-files/W25N01GV%20Rev%20R%20070323.pdf
#
# FR=104 MHz, quad read/prog (9.6 ns * 8/4)
# => +~19 ns for bus
#
NAND_READ_SIZE  ?= 512
NAND_PROG_SIZE  ?= 512
NAND_ERASE_SIZE ?= 131072
NAND_LFS3_BLOCK_SIZE ?= 131072
NAND_LFS3NB_BLOCK_SIZE ?= 131072
NAND_LFS2_BLOCK_SIZE ?= 131072
NAND_SPIFFS_BLOCK_SIZE ?= 131072
NAND_YAFFS2_BLOCK_SIZE ?= 131072
NAND_READ_TIME  ?= 31     # tRD1=25 us, p=2048, s=512 (25 us / 2048 + bus)
NAND_PROG_TIME  ?= 141    # tPP=250 us, p=2048, s=512 (250 us / 2048 + bus)
NAND_ERASE_TIME ?= 15     # tBE=2 ms, block=131072 (2 ms / 131072)


# filesystems to measure code size
CODEMAP_FSS ?= lfs3 lfs3nb lfs2 lfs1 spiffs yaffs2
CODEMAP_RDONLY_FSS ?= lfs3 lfs3nb lfs2 spiffs

# filesystems/sims to benchmark
BENCH_FSS ?= lfs3 lfs3nb lfs2 spiffs yaffs2
BENCH_SIMS ?= emmc nor nand

# poor man's uppercase
U_lfs3   = LFS3
U_lfs3nb = LFS3NB
U_lfs2   = LFS2
U_lfs1   = LFS1
U_spiffs = SPIFFS
U_yaffs2 = YAFFS2

U_emmc = EMMC
U_nor  = NOR
U_nand = NAND

# some other aliases
N_lfs3   = 3
N_lfs3nb = 30
N_lfs2   = 2
N_lfs1   = 1
N_spiffs = 4
N_yaffs2 = 5

I_lfs3   = 0
I_lfs3nb = 1
I_lfs2   = 2
I_lfs1   = 3
I_spiffs = 4
I_yaffs2 = 5


# find source files

# common benches
BENCHES ?= $(wildcard benches/*.toml)

# littlefs3 bench-runner and sources
BENCH_LFS3_RUNNER ?= $(BUILDDIR)/bench_lfs3_runner
BENCH_LFS3_FILTER ?= sed -n -e'1p' -e'/\<lfs3_emubd/d' -e'/\<lfs3/p'
BENCH_LFS3_CFLAGS += -DLFS3=1 -DLFS3_YES_BMAP=1
CODEMAP_LFS3_SRC ?= $(filter-out %.t.c %.b.c %.a.c,$(wildcard littlefs3/*.c))
CODEMAP_LFS3_OBJ := $(CODEMAP_LFS3_SRC:%.c=$(BUILDDIR)/%.lfs3.o)
CODEMAP_LFS3_DEP := $(CODEMAP_LFS3_OBJ:.o=.d)
CODEMAP_LFS3_CI  := $(CODEMAP_LFS3_OBJ:.o=.ci)
BENCH_LFS3_SRC ?= \
		$(CODEMAP_LFS3_SRC) \
		$(filter-out %.t.c %.b.c %.a.c,$(wildcard bd/*.c)) \
		runners/bench_runner.c \
		benches/bench_helpers.c
BENCH_LFS3_B   := \
		$(BENCH_LFS3_SRC:%.c=$(BUILDDIR)/%.b.c) \
		$(BENCHES:%.toml=$(BUILDDIR)/%.b.c)
BENCH_LFS3_A   := $(BENCH_LFS3_B:.b.c=.b.a.c)
BENCH_LFS3_OBJ := $(BENCH_LFS3_A:.b.a.c=.lfs3.b.a.o)
BENCH_LFS3_DEP := $(BENCH_LFS3_OBJ:.o=.d)
BENCH_LFS3_CI  := $(BENCH_LFS3_OBJ:.o=.ci)

# littlefs3 no-bmap bench-runner
BENCH_LFS3NB_RUNNER ?= $(BUILDDIR)/bench_lfs3nb_runner
BENCH_LFS3NB_FILTER ?= $(BENCH_LFS3_FILTER)
BENCH_LFS3NB_CFLAGS += -DLFS3=1
CODEMAP_LFS3NB_OBJ := $(CODEMAP_LFS3_SRC:%.c=$(BUILDDIR)/%.lfs3nb.o)
CODEMAP_LFS3NB_DEP := $(CODEMAP_LFS3NB_OBJ:.o=.d)
CODEMAP_LFS3NB_CI  := $(CODEMAP_LFS3NB_OBJ:.o=.ci)
BENCH_LFS3NB_OBJ := $(BENCH_LFS3_A:.b.a.c=.lfs3nb.b.a.o)
BENCH_LFS3NB_DEP := $(BENCH_LFS3NB_OBJ:.o=.d)
BENCH_LFS3NB_CI  := $(BENCH_LFS3NB_OBJ:.o=.ci)

# littlefs2 bench-runner and sources
BENCH_LFS2_RUNNER ?= $(BUILDDIR)/bench_lfs2_runner
BENCH_LFS2_FILTER ?= sed -n -e'1p' -e'/\<lfs2/p'
BENCH_LFS2_CFLAGS += -DLFS2=1
CODEMAP_LFS2_SRC ?= $(filter-out %.t.c %.b.c %.a.c,$(wildcard littlefs2/*.c))
CODEMAP_LFS2_OBJ := $(CODEMAP_LFS2_SRC:%.c=$(BUILDDIR)/%.lfs2.o)
CODEMAP_LFS2_DEP := $(CODEMAP_LFS2_OBJ:.o=.d)
CODEMAP_LFS2_CI  := $(CODEMAP_LFS2_OBJ:.o=.ci)
BENCH_LFS2_SRC ?= \
		$(CODEMAP_LFS2_SRC) \
		$(filter-out %.t.c %.b.c %.a.c,$(wildcard bd/*.c)) \
		runners/bench_runner.c \
		benches/bench_helpers.c
BENCH_LFS2_B   := \
		$(BENCH_LFS2_SRC:%.c=$(BUILDDIR)/%.b.c) \
		$(BENCHES:%.toml=$(BUILDDIR)/%.b.c)
BENCH_LFS2_A   := $(BENCH_LFS2_B:.b.c=.b.a.c)
BENCH_LFS2_OBJ := $(BENCH_LFS2_A:.b.a.c=.lfs2.b.a.o)
BENCH_LFS2_DEP := $(BENCH_LFS2_OBJ:.o=.d)
BENCH_LFS2_CI  := $(BENCH_LFS2_OBJ:.o=.ci)

# littlefs1 sources
BENCH_LFS1_CFLAGS += -DLFS1=1
CODEMAP_LFS1_SRC ?= $(filter-out %.t.c %.b.c %.a.c,$(wildcard littlefs1/*.c))
CODEMAP_LFS1_OBJ := $(CODEMAP_LFS1_SRC:%.c=$(BUILDDIR)/%.lfs1.o)
CODEMAP_LFS1_DEP := $(CODEMAP_LFS1_SRC:%.c=$(BUILDDIR)/%.lfs1.d)
CODEMAP_LFS1_CI  := $(CODEMAP_LFS1_SRC:%.c=$(BUILDDIR)/%.lfs1.ci)

# spiffs bench-runner and sources
BENCH_SPIFFS_RUNNER ?= $(BUILDDIR)/bench_spiffs_runner
BENCH_SPIFFS_FILTER ?= sed -n -e'1p' -e'/\<SPIFFS/p'
BENCH_SPIFFS_CFLAGS += -DSPIFFS=1
CODEMAP_SPIFFS_SRC ?= \
		$(filter-out %.t.c %.b.c %.a.c,$(wildcard spiffs/src/*.c))
CODEMAP_SPIFFS_OBJ := $(CODEMAP_SPIFFS_SRC:%.c=$(BUILDDIR)/%.spiffs.o)
CODEMAP_SPIFFS_DEP := $(CODEMAP_SPIFFS_OBJ:.o=.d)
CODEMAP_SPIFFS_CI  := $(CODEMAP_SPIFFS_OBJ:.o=.ci)
BENCH_SPIFFS_SRC ?= \
		$(CODEMAP_SPIFFS_SRC) \
		$(filter-out %.t.c %.b.c %.a.c,$(wildcard bd/*.c)) \
		runners/bench_runner.c \
		benches/bench_helpers.c
BENCH_SPIFFS_B   := \
		$(BENCH_SPIFFS_SRC:%.c=$(BUILDDIR)/%.b.c) \
		$(BENCHES:%.toml=$(BUILDDIR)/%.b.c)
# let's not stress test prettyasserts right now
BENCH_SPIFFS_A   := \
		$(patsubst %.b.c,%.b.a.c, \
			$(filter-out $(BUILDDIR)/spiffs/%,$(BENCH_SPIFFS_B))) \
		$(filter $(BUILDDIR)/spiffs/%,$(BENCH_SPIFFS_B))
BENCH_SPIFFS_OBJ := \
		$(patsubst %.b.a.c,%.spiffs.b.a.o,\
		$(patsubst %.b.c,%.spiffs.b.o,\
			$(BENCH_SPIFFS_A)))
BENCH_SPIFFS_DEP := $(BENCH_SPIFFS_OBJ:.o=.d)
BENCH_SPIFFS_CI  := $(BENCH_SPIFFS_OBJ:.o=.ci)

# yaffs2 bench-runner and sources
#
# note yaffs2 needs a preprocessing step with handle_common.sh
#
# we're feeling monstrous today so instead of actually running yaffs2's
# handle_common.sh script, just parse it for the info we need
#
# two hacks:
#
# - force inject yaffscfg.h into all files, sometimes redundantly
#
#   yaffs2 doesn't seem to consistently include yaffscfg.h, though this
#   may be a case where I'm misunderstanding yaffs2 configuration works,
#   that or a side-effect of yaffs2 being Linux-first
#
# - force yaffsfs_handlesInitialised to be non-static
#
#   there doesn't seem to be any other way to force reset yaffs2's
#   global state after a bench failure
#
YAFFS2_CORE_C := $(shell grep -o '[^ ]*\.c' yaffs2/direct/handle_common.sh)
YAFFS2_CORE_H := $(shell grep -o '[^ ]*\.h' yaffs2/direct/handle_common.sh)
YAFFS2_CORE_E := \
		-e '1i\#include "yaffscfg.h"' \
		$(shell grep -o '\-e "[^"]*"' yaffs2/direct/handle_common.sh)
YAFFS2_DIRECT_C := $(notdir $(wildcard yaffs2/direct/*.c))
YAFFS2_DIRECT_H := $(filter-out yaffscfg.h,\
		$(notdir $(wildcard yaffs2/direct/*.h)))
YAFFS2_DIRECT_E := \
		-e '1i\#include "yaffscfg.h"' \
		-e 's/static int yaffsfs_handlesInitialised/$\
			int yaffsfs_handlesInitialised/'
BENCH_YAFFS2_RUNNER ?= $(BUILDDIR)/bench_yaffs2_runner
BENCH_YAFFS2_FILTER ?= sed -n -e'1p' -e'/\<yaffs/p'
BENCH_YAFFS2_CFLAGS += -DYAFFS2=1
CODEMAP_YAFFS2_SRC  ?= \
		$(addprefix yaffs2/core/,$(YAFFS2_CORE_C)) \
		$(addprefix yaffs2/direct/,$(YAFFS2_DIRECT_C))
CODEMAP_YAFFS2_SRC_ := \
		$(addprefix $(BUILDDIR)/yaffs2/,\
			$(YAFFS2_CORE_C) \
			$(YAFFS2_DIRECT_C))
CODEMAP_YAFFS2_OBJ  := $(CODEMAP_YAFFS2_SRC_:.c=.yaffs2.o)
CODEMAP_YAFFS2_DEP  := $(CODEMAP_YAFFS2_OBJ:.o=.d)
CODEMAP_YAFFS2_CI   := $(CODEMAP_YAFFS2_OBJ:.o=.ci)
BENCH_YAFFS2_SRC  ?= \
		$(CODEMAP_YAFFS2_SRC) \
		$(filter-out %.t.c %.b.c %.a.c,$(wildcard bd/*.c)) \
		runners/bench_runner.c \
		benches/bench_helpers.c
BENCH_YAFFS2_SRC_ := \
		$(CODEMAP_YAFFS2_SRC_) \
		$(filter-out %.t.c %.b.c %.a.c,$(wildcard bd/*.c)) \
		runners/bench_runner.c \
		benches/bench_helpers.c
BENCH_YAFFS2_B 	  := \
		$(patsubst %.c,$(BUILDDIR)/%.b.c,\
			$(filter-out $(BUILDDIR)/%,$(BENCH_YAFFS2_SRC_))) \
		$(patsubst %.c,%.b.c,\
			$(filter $(BUILDDIR)/%,$(BENCH_YAFFS2_SRC_))) \
		$(BENCHES:%.toml=$(BUILDDIR)/%.b.c)
# let's not stress test prettyasserts right now
BENCH_YAFFS2_A    := \
		$(patsubst %.b.c,%.b.a.c, \
			$(filter-out $(BUILDDIR)/yaffs2/%,$(BENCH_YAFFS2_B))) \
		$(filter $(BUILDDIR)/yaffs2/%,$(BENCH_YAFFS2_B))
BENCH_YAFFS2_OBJ  := \
		$(patsubst %.b.a.c,%.yaffs2.b.a.o,\
		$(patsubst %.b.c,%.yaffs2.b.o,\
			$(BENCH_YAFFS2_A)))
BENCH_YAFFS2_DEP  := $(BENCH_YAFFS2_OBJ:.o=.d)
BENCH_YAFFS2_CI   := $(BENCH_YAFFS2_OBJ:.o=.ci)



# overridable tools/flags
CC            ?= gcc
AR            ?= ar
SIZE          ?= size
CTAGS         ?= ctags
OBJDUMP       ?= objdump
VALGRIND      ?= valgrind
GDB           ?= gdb
PERF          ?= perf
PRETTYASSERTS ?= ./scripts/prettyasserts.py

# c flags
CFLAGS += -fcallgraph-info=su
CFLAGS += -g3
CFLAGS += -I. -Ilittlefs3 -Ilittlefs2
CFLAGS += -Ispiffs/src
CFLAGS += -I$(BUILDDIR)/yaffs2
CFLAGS += -std=c99 -Wall -Wextra -pedantic
# labels are useful for debugging, in-function organization, etc
CFLAGS += -Wno-unused-label
CFLAGS += -Wno-unused-function
CFLAGS += -Wno-format-overflow
# compiler bug: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=101854
CFLAGS += -Wno-stringop-overflow
CFLAGS += -ftrack-macro-expansion=0
# wrap malloc/free/realloc for heap measurements
CFLAGS += -Wl,--wrap=malloc
CFLAGS += -Wl,--wrap=free
CFLAGS += -Wl,--wrap=realloc
# gc unused functions
CFLAGS += -ffunction-sections
CFLAGS += -fdata-sections
CFLAGS += -Wl,--gc-sections
ifdef DEBUG
CFLAGS += -O0
else
CFLAGS += -Os
CFLAGS += -DNDEBUG
CFLAGS += $(foreach fs,LFS LFS1 LFS2 LFS3,-D$(fs)_NO_LOG)
CFLAGS += $(foreach fs,LFS LFS1 LFS2 LFS3,-D$(fs)_NO_DEBUG)
CFLAGS += $(foreach fs,LFS LFS1 LFS2 LFS3,-D$(fs)_NO_INFO)
CFLAGS += $(foreach fs,LFS LFS1 LFS2 LFS3,-D$(fs)_NO_WARN)
CFLAGS += $(foreach fs,LFS LFS1 LFS2 LFS3,-D$(fs)_NO_ERROR)
CFLAGS += $(foreach fs,LFS LFS1 LFS2 LFS3,-D$(fs)_NO_ASSERT)
endif
ifdef TRACE
CFLAGS += $(foreach fs,LFS LFS1 LFS2 LFS3,-D$(fs)_YES_TRACE)
endif

# also forward all LFS_*, LFS2_*, and LFS3*_ environment variables
CFLAGS += $(foreach d,$(filter LFS_%,$(.VARIABLES)),-D$d=$($d))
CFLAGS += $(foreach d,$(filter LFS1_%,$(.VARIABLES)),-D$d=$($d))
CFLAGS += $(foreach d,$(filter LFS2_%,$(.VARIABLES)),-D$d=$($d))
CFLAGS += $(foreach d,$(filter LFS3_%,$(.VARIABLES)),-D$d=$($d))

# TODO eventually we'll need these for cross compiling
# # cross-compile codemap, we don't really care about x86 code size
# CODEMAP_CC ?= arm-linux-gnueabi-gcc -mthumb --static -Wno-stringop-overflow
# CODEMAP_CFLAGS += $(foreach fs,LFS LFS1 LFS2 LFS3,-D$(fs)_NO_LOG)
# CODEMAP_CFLAGS += $(foreach fs,LFS LFS1 LFS2 LFS3,-D$(fs)_NO_DEBUG)
# CODEMAP_CFLAGS += $(foreach fs,LFS LFS1 LFS2 LFS3,-D$(fs)_NO_INFO)
# CODEMAP_CFLAGS += $(foreach fs,LFS LFS1 LFS2 LFS3,-D$(fs)_NO_WARN)
# CODEMAP_CFLAGS += $(foreach fs,LFS LFS1 LFS2 LFS3,-D$(fs)_NO_ERROR)
# CODEMAP_CFLAGS += $(foreach fs,LFS LFS1 LFS2 LFS3,-D$(fs)_NO_ASSERT)

# rdonly c flags
RDONLY_CFLAGS += -DLFS3_RDONLY
RDONLY_CFLAGS += -DLFS2_READONLY
RDONLY_CFLAGS += -DSPIFFS_READ_ONLY

# bench.py -c flags
ifdef VERBOSE
BENCHCFLAGS += -v
endif

# this is a bit of a hack, but we want to make sure the BUILDDIR
# directory structure is correct before we run any commands
ifneq ($(BUILDDIR),.)
$(if $(findstring n,$(MAKEFLAGS)),, $(shell mkdir -p \
	$(BUILDDIR) \
	$(CODEMAPSDIR) \
	$(RESULTSDIR) \
	$(PLOTSDIR) \
	$(TIKZDIR) \
    $(dir \
		$(foreach fs, $(CODEMAP_FSS), \
			$(CODEMAP_$(U_$(fs))_OBJ) \
		$(foreach fs, $(BENCH_FSS), \
			$(BENCH_$(U_$(fs))_OBJ))))))
endif

# just use bash for everything, process substitution my beloved!
SHELL = /bin/bash


# top-level commands

## Build the bench-runners
.PHONY: build bench-runner build-benches
build bench-runner build-benches: CFLAGS+=$(BENCH_CFLAGS)
# note we remove some binary dependent files during compilation,
# otherwise it's way to easy to end up with outdated results
build bench-runner build-benches: \
		$(foreach fs, $(BENCH_FSS), \
			$(BENCH_$(U_$(fs))_RUNNER))

## Generate a ctags file
.PHONY: tags ctags
tags ctags:
	$(strip $(CTAGS) \
		--totals --fields=+n --c-types=+p \
		$(shell find -H -name '*.h'))
	$(strip $(CTAGS) \
		--totals --append --fields=+n \
		$(foreach fs, $(BENCH_FSS), \
			$(BENCH_$(U_$(fs))_SRC)))

## Show this help text
.PHONY: help
help:
	@$(strip awk '/^## / { \
			sub(/^## /,""); \
			getline rule; \
			while (rule ~ /^(#|\.PHONY|ifdef|ifndef)/) getline rule; \
			gsub(/:.*/, "", rule); \
			if (length(rule) <= 21) { \
				printf "%2s%-21s %s\n", "", rule, $$0; \
			} else { \
				printf "%2s%s\n", "", rule; \
				printf "%24s%s\n", "", $$0; \
			} \
		}' $(MAKEFILE_LIST))

## Bench, plot, codemap, this should do everything
.PHONY: all
all: \
		build \
		codemap \
		bench \
		plot

## Find total section sizes
.PHONY: size
size: \
		$(foreach fs, $(BENCH_FSS), \
			$(BENCH_$(U_$(fs))_RUNNER))
	$(SIZE) -t $^

## Find compile-time sizes _before_ link-time gc
.PHONY: sizes sizes-prelink
sizes sizes-prelink: \
		$(foreach fs, $(CODEMAP_FSS), \
			$(CODEMAP_$(U_$(fs))_OBJ) \
			$(CODEMAP_$(U_$(fs))_CI))
	$(strip ./scripts/csv.py \
		$(foreach fs, $(CODEMAP_FSS), \
			<(./scripts/csv.py \
				<(./scripts/code.py $(CODEMAP_$(U_$(fs))_OBJ) \
					-bfunction -o-) \
				-bi=$(I_$(fs)) -bfs=$(fs) -bfunction -o-) \
			<(./scripts/csv.py \
				<(./scripts/data.py $(CODEMAP_$(U_$(fs))_OBJ) \
					-bfunction -o-) \
				-bi=$(I_$(fs)) -bfs=$(fs) -bfunction -o-) \
			<(./scripts/csv.py \
				<(./scripts/stack.py $(CODEMAP_$(U_$(fs))_CI) \
					-bfunction -o-) \
				-bi=$(I_$(fs)) -bfs=$(fs) -bfunction -o-) \
			<(./scripts/csv.py \
				<(./scripts/ctx.py $(CODEMAP_$(U_$(fs))_OBJ) \
					-bfunction -o-) \
				-bi=$(I_$(fs)) -bfs=$(fs) -bfunction -o-)) \
		-Bi -bfs \
		-fcode=code_size \
		-fdata=data_size \
		-fstack='max(stack_limit)' \
		-fctx='max(ctx_size)' \
		--no-total)

## Find rdonly compile-time sizes _before_ link-time gc
.PHONY: sizes-rdonly sizes-rdonly-prelink
sizes-rdonly sizes-rdonly-prelink: \
		$(foreach fs, $(CODEMAP_RDONLY_FSS), \
			$(CODEMAP_$(U_$(fs))_OBJ:.o=.rdonly.o) \
			$(CODEMAP_$(U_$(fs))_CI:.ci=.rdonly.ci))
	$(strip ./scripts/csv.py \
		$(foreach fs, $(CODEMAP_RDONLY_FSS), \
			<(./scripts/csv.py \
				<(./scripts/code.py $(CODEMAP_$(U_$(fs))_OBJ:.o=.rdonly.o) \
					-bfunction -o-) \
				-bi=$(I_$(fs)) -bfs=$(fs) -bfunction -o-) \
			<(./scripts/csv.py \
				<(./scripts/data.py $(CODEMAP_$(U_$(fs))_OBJ:.o=.rdonly.o) \
					-bfunction -o-) \
				-bi=$(I_$(fs)) -bfs=$(fs) -bfunction -o-) \
			<(./scripts/csv.py \
				<(./scripts/stack.py $(CODEMAP_$(U_$(fs))_CI:.ci=.rdonly.ci) \
					-bfunction -o-) \
				-bi=$(I_$(fs)) -bfs=$(fs) -bfunction -o-) \
			<(./scripts/csv.py \
				<(./scripts/ctx.py $(CODEMAP_$(U_$(fs))_OBJ:.o=.rdonly.o) \
					-bfunction -o-) \
				-bi=$(I_$(fs)) -bfs=$(fs) -bfunction -o-)) \
		-Bi -bfs \
		-fcode=code_size \
		-fdata=data_size \
		-fstack='max(stack_limit)' \
		-fctx='max(ctx_size)' \
		--no-total)

## Find compile-time sizes _after_ link-time gc
#
# note we need to filter .ci symbols based on runner symbols picked up
# by code/data/ctx/etc
#
.PHONY: sizes-postlink bench-sizes
sizes-postlink bench-sizes: \
		$(foreach fs, $(BENCH_FSS), \
			$(BENCH_$(U_$(fs))_RUNNER))
	$(strip ./scripts/csv.py \
		$(foreach fs, $(BENCH_FSS), \
			<(./scripts/csv.py \
				<(./scripts/code.py $(BENCH_$(U_$(fs))_RUNNER) \
					-bfunction -o- \
						| $(BENCH_$(U_$(fs))_FILTER)) \
				<(./scripts/data.py $(BENCH_$(U_$(fs))_RUNNER) \
					-bfunction -o- \
						| $(BENCH_$(U_$(fs))_FILTER)) \
				<(./scripts/stack.py $(BENCH_$(U_$(fs))_CI) \
					-bfunction -o- \
						| $(BENCH_$(U_$(fs))_FILTER)) \
				<(./scripts/ctx.py $(BENCH_$(U_$(fs))_RUNNER) \
					-bfunction -o- \
						| $(BENCH_$(U_$(fs))_FILTER)) \
				-bi=$(I_$(fs)) -bfs=$(fs) -bfunction -o-)) \
		-Bi -bfs \
		-fcode=code_size \
		-fdata=data_size \
		-fstack='max((code_size) ? stack_limit : 0)' \
		-fctx='max(ctx_size)' \
		--no-total)



# low-level rules
$(foreach fs, $(CODEMAP_FSS), \
	$(eval -include $(CODEMAP_$(U_$(fs))_DEP)))
$(foreach fs, $(BENCH_FSS), \
	$(eval -include $(BENCH_$(U_$(fs))_DEP)))
.SUFFIXES:
.SECONDARY:
.DELETE_ON_ERROR:
.PHONY: PHONY
PHONY: ;
, := ,


# bench runner rule
#
# $1 - target
# $2 - prerequisites
# $3 - fs type/version
#
define BENCH_RUNNER_RULE
$1: $2
	$(CC) $(CFLAGS) $(BENCH_$(U_$3)_CFLAGS) $$^ $(LFLAGS) -o$$@
endef

$(foreach fs, $(BENCH_FSS), \
	$(eval $(call BENCH_RUNNER_RULE,$\
		$(BENCH_$(U_$(fs))_RUNNER),$\
		$(BENCH_$(U_$(fs))_OBJ),$\
		$(fs))))

# our main build rule generates .o, .d, and .ci files, the latter
# used for stack analysis

# bench .o rule
#
# $1 - targets
# $2 - prerequisite
# $2 - fs type/version
#
define BENCH_O_RULE
$1: $2
	$(CC) -c -MMD $(CFLAGS) $(BENCH_$(U_$3)_CFLAGS) $$< -o$$(firstword $$@)
endef

$(foreach fs, $(CODEMAP_FSS), \
	$(eval $(call BENCH_O_RULE,$\
		$(BUILDDIR)/%.$(fs).o $(BUILDDIR)/%.$(fs).ci,$\
		%.c,$\
		$(fs))))

$(foreach fs, $(CODEMAP_FSS), \
	$(eval $(call BENCH_O_RULE,$\
		$(BUILDDIR)/%.$(fs).o $(BUILDDIR)/%.$(fs).ci,$\
		$(BUILDDIR)/%.c,$\
		$(fs))))

$(foreach fs, $(BENCH_FSS), \
	$(eval $(call BENCH_O_RULE,$\
		$(BUILDDIR)/%.$(fs).b.o $(BUILDDIR)/%.$(fs).b.ci,$\
		%.b.c,$\
		$(fs))))

$(foreach fs, $(BENCH_FSS), \
	$(eval $(call BENCH_O_RULE,$\
		$(BUILDDIR)/%.$(fs).b.o $(BUILDDIR)/%.$(fs).b.ci,$\
		$(BUILDDIR)/%.b.c,$\
		$(fs))))

$(foreach fs, $(BENCH_FSS), \
	$(eval $(call BENCH_O_RULE,$\
		$(BUILDDIR)/%.$(fs).b.a.o $(BUILDDIR)/%.$(fs).b.a.ci,$\
		%.b.a.c,$\
		$(fs))))

$(foreach fs, $(BENCH_FSS), \
	$(eval $(call BENCH_O_RULE,$\
		$(BUILDDIR)/%.$(fs).b.a.o $(BUILDDIR)/%.$(fs).b.a.ci,$\
		$(BUILDDIR)/%.b.a.c,$\
		$(fs))))

# bench rdonly .o rule
#
# $1 - targets
# $2 - prerequisites
# $2 - fs type/version
#
define BENCH_RDONLY_O_RULE
$1: $2
	$$(strip $(CC) -c -MMD \
		$(CFLAGS) $(RDONLY_CFLAGS) $(BENCH_$(U_$3)_CFLAGS) \
		$$< -o$$(firstword $$@))
endef

$(foreach fs, $(CODEMAP_RDONLY_FSS), \
	$(eval $(call BENCH_RDONLY_O_RULE,$\
		$(BUILDDIR)/%.$(fs).rdonly.o $(BUILDDIR)/%.$(fs).rdonly.ci,$\
		%.c,$\
		$(fs))))

$(foreach fs, $(CODEMAP_RDONLY_FSS), \
	$(eval $(call BENCH_RDONLY_O_RULE,$\
		$(BUILDDIR)/%.$(fs).rdonly.o $(BUILDDIR)/%.$(fs).rdonly.ci,$\
		$(BUILDDIR)/%.c,$\
		$(fs))))

$(BUILDDIR)/%.s: %.c
	$(CC) -S $(CFLAGS) $< -o$@

$(BUILDDIR)/%.s: $(BUILDDIR)/%.c
	$(CC) -S $(CFLAGS) $< -o$@

$(BUILDDIR)/%.a.c: %.c
	$(PRETTYASSERTS) -Plfs_ -Plfs1_ -Plfs2_ -Plfs3_ $< -o$@

$(BUILDDIR)/%.a.c: $(BUILDDIR)/%.c
	$(PRETTYASSERTS) -Plfs_ -Plfs1_ -Plfs2_ -Plfs3_ $< -o$@

$(BUILDDIR)/%.b.c: %.toml
	./scripts/bench.py -c $< $(BENCHCFLAGS) -o$@

$(BUILDDIR)/%.b.c: %.c $(BENCHES)
	./scripts/bench.py -c $(BENCHES) -s $< $(BENCHCFLAGS) -o$@

$(BUILDDIR)/%.b.c: $(BUILDDIR)/%.c $(BENCHES)
	./scripts/bench.py -c $(BENCHES) -s $< $(BENCHCFLAGS) -o$@

# yaffs2 preprocessing rules
#
# yaffs2 expects some core names to be preprocessed in direct mode,
# which we've grepped and apply here, see above
#
$(BENCH_YAFFS2_OBJ): \
		$(addprefix $(BUILDDIR)/yaffs2/,\
			$(YAFFS2_CORE_H) \
			$(YAFFS2_DIRECT_H))

$(BUILDDIR)/yaffs2/%.h: yaffs2/direct/%.h
	sed $< $(YAFFS2_DIRECT_E) >$@

$(BUILDDIR)/yaffs2/%.h: yaffs2/core/%.h
	sed $< $(YAFFS2_CORE_E) >$@

$(BUILDDIR)/yaffs2/%.c: yaffs2/direct/%.c
	sed $< $(YAFFS2_DIRECT_E) >$@

$(BUILDDIR)/yaffs2/%.c: yaffs2/core/%.c
	sed $< $(YAFFS2_CORE_E) >$@




#======================================================================#
# first, some codemap rules                                            #
#======================================================================#

# plot config
ifndef LIGHT
CODEMAPFLAGS += --dark
endif

# give some of the bigger subsystems explicit colors, to help with
# comparisons and to avoid similarly colored neighbors
ifdef LIGHT
CODEMAP_COLORS += -C'file=\#80be8e'   	   # was '#55a868bf', # green
CODEMAP_COLORS += -C'lfs*_file=\#80be8e'   # was '#55a868bf', # green
CODEMAP_COLORS += -C'lfs*_data=\#80be8e'   # was '#55a868bf', # green
CODEMAP_COLORS += -C'lfs*_mdir=\#d9cb97'   # was '#ccb974bf', # yellow
CODEMAP_COLORS += -C'lfs*_dir=\#d9cb97'    # was '#ccb974bf', # yellow
CODEMAP_COLORS += -C'lfs*_mtree=\#a195c6'  # was '#8172b3bf', # purple
CODEMAP_COLORS += -C'lfs*_btree=\#7995c4'  # was '#4c72b0bf', # blue
CODEMAP_COLORS += -C'lfs*_ctz=\#7995c4'    # was '#4c72b0bf', # blue
CODEMAP_COLORS += -C'lfs*_bshrub=\#8bc8da' # was '#64b5cdbf', # cyan
CODEMAP_COLORS += -C'lfs*_rbyd=\#d37a7d'   # was '#c44e52bf', # red
CODEMAP_COLORS += -C'lfs=\#ae9a88'         # was '#937860bf', # brown
CODEMAP_COLORS += -C'lfs1=\#ae9a88'        # was '#937860bf', # brown
CODEMAP_COLORS += -C'lfs2=\#ae9a88'        # was '#937860bf', # brown
CODEMAP_COLORS += -C'lfs3=\#ae9a88'        # was '#937860bf', # brown
CODEMAP_COLORS += -C'lfs*_fs=\#ae9a88'     # was '#937860bf', # brown
CODEMAP_COLORS += -C'lfs*_bd=\#a9a9a9'     # was '#8c8c8cbf', # gray
else
CODEMAP_COLORS += -C'file=\#6aac79'        # was '#8de5a1bf', # green
CODEMAP_COLORS += -C'lfs*_file=\#6aac79'   # was '#8de5a1bf', # green
CODEMAP_COLORS += -C'lfs*_data=\#6aac79'   # was '#8de5a1bf', # green
CODEMAP_COLORS += -C'lfs*_mdir=\#bfbe7a'   # was '#fffea3bf', # yellow
CODEMAP_COLORS += -C'lfs*_dir=\#bfbe7a'    # was '#fffea3bf', # yellow
CODEMAP_COLORS += -C'lfs*_mtree=\#9c8cbf'  # was '#d0bbffbf', # purple
CODEMAP_COLORS += -C'lfs*_btree=\#7997b7'  # was '#a1c9f4bf', # blue
CODEMAP_COLORS += -C'lfs*_ctz=\#7995c4'    # was '#4c72b0bf', # blue
CODEMAP_COLORS += -C'lfs*_bshrub=\#8bb5b4' # was '#b9f2f0bf', # cyan
CODEMAP_COLORS += -C'lfs*_rbyd=\#bf7774'   # was '#ff9f9bbf', # red
CODEMAP_COLORS += -C'lfs=\#a68c74'         # was '#debb9bbf', # brown
CODEMAP_COLORS += -C'lfs1=\#a68c74'        # was '#debb9bbf', # brown
CODEMAP_COLORS += -C'lfs2=\#a68c74'        # was '#debb9bbf', # brown
CODEMAP_COLORS += -C'lfs3=\#a68c74'        # was '#debb9bbf', # brown
CODEMAP_COLORS += -C'lfs*_fs=\#a68c74'     # was '#debb9bbf', # brown
CODEMAP_COLORS += -C'lfs*_bd=\#9b9b9b'     # was '#cfcfcfbf', # gray
endif


# overrideable codemap rules
CODEMAP_RULES ?= \
		codemap-default \
		codemap-rdonly

## Generate all codemaps!
.PHONY: codemap codemaps codemap-all
codemap codemaps codemap-all: $(CODEMAP_RULES)

## Generate codemaps for the default build
.PHONY: codemap-default
codemap-default: \
		$(foreach fs, $(CODEMAP_FSS), \
			$(CODEMAPSDIR)/codemap_$(fs).svg \
			$(CODEMAPSDIR)/codemap_$(fs)_tiny.svg)

## Generate codemaps for the rdonly build
.PHONY: codemap-rdonly
codemap-rdonly: \
		$(foreach fs, $(CODEMAP_RDONLY_FSS), \
			$(CODEMAPSDIR)/codemap_$(fs)_rdonly.svg \
			$(CODEMAPSDIR)/codemap_$(fs)_rdonly_tiny.svg)


# codemap rules!

# normal codemap rule
#
# $1 - target
# $2 - obj/callgraph files
# $3 - fs type/version
#
define CODEMAP_RULE
$1: $2
	$$(strip ./scripts/codemapsvg.py $$^ \
		--title="$3 code %(code)s stack %(stack)s ctx %(ctx)s" \
		-W1125 -H525 \
		$$(CODEMAP_COLORS) \
		$$(CODEMAPFLAGS) \
		-o$$@ \
		&& ./scripts/codemap.py $$^ --no-header)
endef

# tiny codemap rule
#
# $1 - target
# $2 - obj/callgraph files
#
define CODEMAP_TINY_RULE
$1: $2
	$$(strip ./scripts/codemapsvg.py $$^ \
		--tiny --background=\#00000000 \
		$$(CODEMAP_COLORS) \
		$$(CODEMAPFLAGS) \
		-o$$@ \
		&& ./scripts/codemap.py $$^ --no-header)
endef

# default codemap rules
$(foreach fs, $(CODEMAP_FSS),$\
	$(eval $(call CODEMAP_RULE,$\
			$(CODEMAPSDIR)/codemap_$(fs).svg,$\
			$(CODEMAP_$(U_$(fs))_OBJ) $\
				$(CODEMAP_$(U_$(fs))_CI),$\
			$(fs))))

# tiny default codemap rules
$(foreach fs, $(CODEMAP_FSS),$\
	$(eval $(call CODEMAP_TINY_RULE,$\
			$(CODEMAPSDIR)/codemap_$(fs)_tiny.svg,$\
			$(CODEMAP_$(U_$(fs))_OBJ) $\
				$(CODEMAP_$(U_$(fs))_CI))))

# rdonly codemap rules
$(foreach fs, $(CODEMAP_RDONLY_FSS),$\
	$(eval $(call CODEMAP_RULE,$\
			$(CODEMAPSDIR)/codemap_$(fs)_rdonly.svg,$\
			$(CODEMAP_$(U_$(fs))_OBJ:.o=.rdonly.o) $\
				$(CODEMAP_$(U_$(fs))_CI:.ci=.rdonly.ci),$\
			$(fs))))

# tiny rdonly codemap rules
$(foreach fs, $(CODEMAP_RDONLY_FSS),$\
	$(eval $(call CODEMAP_TINY_RULE,$\
			$(CODEMAPSDIR)/codemap_$(fs)_rdonly_tiny.svg,$\
			$(CODEMAP_$(U_$(fs))_OBJ:.o=.rdonly.o) $\
				$(CODEMAP_$(U_$(fs))_CI:.ci=.rdonly.ci))))




#======================================================================#
# ok! here's our actual benchmark rules      						   #
#======================================================================#

# bench.py flags
# explicit disk path?
ifdef DISK_PATH
BENCHFLAGS += -d$(DISK_PATH)
DISK_BIG = 1
endif
# give us a big disk
BENCHFLAGS += -DDISK_SIZE=$(DISK_SIZE)
BENCHFLAGS += -b
# note the presence of a physical disk means we CAN NOT run in parallel
ifndef DISK_BIG
# just always run benches in parallel, this makefile uses too much RAM
# to easily parallelize at the rule level
BENCHFLAGS += -j
# # forward -j flag
# BENCHFLAGS += $(filter -j%,$(MAKEFLAGS))
endif
ifdef PERFGEN
BENCHFLAGS += -p$(BENCH_LFS3_PERF)
endif
ifdef PERFBDGEN
BENCHFLAGS += -t$(BENCH_LFS3_TRACE) --trace-backtrace --trace-freq=100
endif
ifdef VERBOSE
BENCHFLAGS  += -v
endif
ifdef EXEC
BENCHFLAGS += --exec="$(EXEC)"
endif
ifneq ($(GDB),gdb)
BENCHFLAGS += --gdb-path="$(GDB)"
endif
ifneq ($(VALGRIND),valgrind)
BENCHFLAGS += --valgrind-path="$(VALGRIND)"
endif
ifneq ($(PERF),perf)
BENCHFLAGS += --perf-path="$(PERF)"
endif


# overrideable bench rules
BENCH_RULES ?= \
		bench-p26-litmus \
		bench-p26-wt \
		bench-p26-rt

## Run all benchmarks!
.PHONY: bench bench-all
bench bench-all: $(BENCH_RULES)

## Mark current results as up-to-date to prevent reruns
.PHONY: reuse-results
reuse-results:
	find $(RESULTSDIR) -name '*.csv' -execdir touch '{}' ';'

## Run p26 litmus benchmarks
.PHONY: bench-p26-litmus
bench-p26-litmus: \
		bench-p26-litmus-linear \
		bench-p26-litmus-random \
		bench-p26-litmus-many \
		bench-p26-litmus-logging

## Run p26 litmus linear benchmarks
.PHONY: bench-p26-litmus-linear
bench-p26-litmus-linear: \
		$(foreach fs, $(BENCH_FSS), \
			$(foreach sim, $(BENCH_SIMS), \
				$(RESULTSDIR)/bench_p26_litmus_linear.$(fs).$(sim).csv))

## Run p26 litmus random benchmarks
.PHONY: bench-p26-litmus-random
bench-p26-litmus-random: \
		$(foreach fs, $(BENCH_FSS), \
			$(foreach sim, $(BENCH_SIMS), \
				$(RESULTSDIR)/bench_p26_litmus_random.$(fs).$(sim).csv))

## Run p26 litmus many benchmarks
.PHONY: bench-p26-litmus-many
bench-p26-litmus-many: \
		$(foreach fs, $(BENCH_FSS), \
			$(foreach sim, $(BENCH_SIMS), \
				$(RESULTSDIR)/bench_p26_litmus_many.$(fs).$(sim).csv))

## Run p26 litmus logging benchmarks
.PHONY: bench-p26-litmus-logging
bench-p26-litmus-logging: \
		$(foreach fs, $(BENCH_FSS), \
			$(foreach sim, $(BENCH_SIMS), \
				$(RESULTSDIR)/bench_p26_litmus_logging.$(fs).$(sim).csv))

## Run p26 write-throughput benchmarks
.PHONY: bench-p26-wt
bench-p26-wt: \
		bench-p26-wt-linear \
		bench-p26-wt-random \
		bench-p26-wt-many \
		bench-p26-wt-logging

## Run p26 write-throughput linear benchmarks
.PHONY: bench-p26-wt-linear
bench-p26-wt-linear: \
		$(foreach fs, $(BENCH_FSS), \
			$(foreach sim, $(BENCH_SIMS), \
				$(RESULTSDIR)/bench_p26_wt_linear.$(fs).$(sim).csv))

## Run p26 write-throughput random benchmarks
.PHONY: bench-p26-wt-random
bench-p26-wt-random: \
		$(foreach fs, $(BENCH_FSS), \
			$(foreach sim, $(BENCH_SIMS), \
				$(RESULTSDIR)/bench_p26_wt_random.$(fs).$(sim).csv))

## Run p26 write-throughput many benchmarks
.PHONY: bench-p26-wt-many
bench-p26-wt-many: \
		$(foreach fs, $(BENCH_FSS), \
			$(foreach sim, $(BENCH_SIMS), \
				$(RESULTSDIR)/bench_p26_wt_many.$(fs).$(sim).csv))

## Run p26 write-throughput logging benchmarks
.PHONY: bench-p26-wt-logging
bench-p26-wt-logging: \
		$(foreach fs, $(BENCH_FSS), \
			$(foreach sim, $(BENCH_SIMS), \
				$(RESULTSDIR)/bench_p26_wt_logging.$(fs).$(sim).csv))

## Run p26 read-throughput benchmarks
.PHONY: bench-p26-rt
bench-p26-rt: \
		bench-p26-rt-linear \
		bench-p26-rt-random \
		bench-p26-rt-many

## Run p26 read-throughput linear benchmarks
.PHONY: bench-p26-rt-linear
bench-p26-rt-linear: \
		$(foreach fs, $(BENCH_FSS), \
			$(foreach sim, $(BENCH_SIMS), \
				$(RESULTSDIR)/bench_p26_rt_linear.$(fs).$(sim).csv))

## Run p26 read-throughput random benchmarks
.PHONY: bench-p26-rt-random
bench-p26-rt-random: \
		$(foreach fs, $(BENCH_FSS), \
			$(foreach sim, $(BENCH_SIMS), \
				$(RESULTSDIR)/bench_p26_rt_random.$(fs).$(sim).csv))

## Run p26 read-throughput many benchmarks
.PHONY: bench-p26-rt-many
bench-p26-rt-many: \
		$(foreach fs, $(BENCH_FSS), \
			$(foreach sim, $(BENCH_SIMS), \
				$(RESULTSDIR)/bench_p26_rt_many.$(fs).$(sim).csv))




# p26 bench rules!

# p26 litmus bench rule
#
# $1 - target
# $2 - bench case
# $3 - fs type/version
# $4 - sim type
#
define BENCH_P26_LITMUS_RULE
ifndef NO_BENCH
$1: $(BENCH_$(U_$3)_RUNNER)
	$$(strip ./scripts/bench.py -R$$< -B $2 \
		$(BENCHFLAGS) \
		-DSIZE=$(P26_LITMUS_SIZE) \
		-DCHUNK=$(P26_LITMUS_CHUNK) \
		-DSTEP=$(P26_LITMUS_STEP) \
		-DSEED="range($(P26_LITMUS_SAMPLES))" \
		-DFS=$(N_$3) \
		-DREAD_SIZE=$($(U_$4)_READ_SIZE) \
		-DPROG_SIZE=$($(U_$4)_PROG_SIZE) \
		-DERASE_SIZE=$($(U_$4)_ERASE_SIZE) \
		-DREAD_TIME=$($(U_$4)_READ_TIME) \
		-DPROG_TIME=$($(U_$4)_PROG_TIME) \
		-DERASE_TIME=$($(U_$4)_ERASE_TIME) \
		-DBLOCK_SIZE=$($(U_$4)_$(U_$3)_BLOCK_SIZE) \
		-o$$@)
else
$1:
	$$(warning NO_BENCH $$@)
endif
endef

$(foreach fs, $(BENCH_FSS),$\
	$(foreach sim, $(BENCH_SIMS),$\
		$(eval $(call BENCH_P26_LITMUS_RULE,$\
				$(RESULTSDIR)/bench_p26_litmus_%.$(fs).$(sim).csv,$\
				bench_p26_litmus_$$*,$\
				$(fs),$\
				$(sim)))))


# p26 read/write-throughput bench rule
#
# $1 - target
# $2 - bench case
# $3 - fs type/version
# $4 - sim type
#
define BENCH_P26_T_RULE
ifndef NO_BENCH
$1: $(BENCH_$(U_$3)_RUNNER)
	$$(strip ./scripts/bench.py -R$$< -B $2 \
		$(BENCHFLAGS) \
		-DSIZE=$(P26_T_SIZES) \
		-DCHUNK=$(P26_T_CHUNK) \
		-DSIM_TIME=$(or $(P26_T_SIM_TIME),0) \
		-DSIM_SIZE=$(or $(P26_T_SIM_SIZE),0) \
		-DFS=$(N_$3) \
		-DREAD_SIZE=$($(U_$4)_READ_SIZE) \
		-DPROG_SIZE=$($(U_$4)_PROG_SIZE) \
		-DERASE_SIZE=$($(U_$4)_ERASE_SIZE) \
		-DREAD_TIME=$($(U_$4)_READ_TIME) \
		-DPROG_TIME=$($(U_$4)_PROG_TIME) \
		-DERASE_TIME=$($(U_$4)_ERASE_TIME) \
		-DBLOCK_SIZE=$($(U_$4)_$(U_$3)_BLOCK_SIZE) \
		-o$$@)
else
$1:
	$$(warning NO_BENCH $$@)
endif
endef

# p26 write-throughput bench rules
$(foreach fs, $(BENCH_FSS),$\
	$(foreach sim, $(BENCH_SIMS),$\
		$(eval $(call BENCH_P26_T_RULE,$\
				$(RESULTSDIR)/bench_p26_wt_%.$(fs).$(sim).csv,$\
				bench_p26_wt_$$*,$\
				$(fs),$\
				$(sim)))))

# p26 read-throughput bench rules
$(foreach fs, $(BENCH_FSS),$\
	$(foreach sim, $(BENCH_SIMS),$\
		$(eval $(call BENCH_P26_T_RULE,$\
				$(RESULTSDIR)/bench_p26_rt_%.$(fs).$(sim).csv,$\
				bench_p26_rt_$$*,$\
				$(fs),$\
				$(sim)))))


## Quick summary of simtimes/simsizes to help debugging
simtime-%: PHONY
	$(strip ./scripts/csv.py \
		$(foreach fs, $(BENCH_FSS), \
			$(foreach sim, $(BENCH_SIMS), \
				$(foreach csv, \
						$(wildcard $(RESULTSDIR)/bench_$(subst -,_,$*)_*$\
							.$(fs).$(sim).csv), \
					<(./scripts/csv.py \
						<(./scripts/csv.py $(csv) \
							-fn \
							-fbench_readed \
							-fbench_proged \
							-fbench_erased \
							-Dbench_creaded='*' \
							-Dbench_cproged='*' \
							-Dbench_cerased='*' \
							-o-) \
						-bfs=$(fs) \
						-bsim=$(sim) \
						-bbench=$(patsubst $\
							$(RESULTSDIR)/bench_$(subst -,_,$*)_%$\
								.$(fs).$(sim).csv,%,$(csv)) \
						-Dm=write,read \
						-fminn='min(n)' \
						-fmaxn='max(n)' \
						-fmint='min( \
							(float(bench_readed)*float(READ_TIME) \
								+ float(bench_proged)*float(PROG_TIME) \
								+ float(bench_erased)*float(ERASE_TIME) \
							) / 1.0e9)' \
						-fmaxt='max( \
							(float(bench_readed)*float(READ_TIME) \
								+ float(bench_proged)*float(PROG_TIME) \
								+ float(bench_erased)*float(ERASE_TIME) \
							) / 1.0e9)' \
						-o-)))) \
		-I \
		-bfs \
		-bsim \
		-bbench \
		-Q)


# quick throughput results recipe
#
# $1 - benchmark
# $2 - fs types/versions
# $3 - sim types
# $4 - benches
#
BENCH_T_RESULT_RECIPE = $(strip ./scripts/csv.py \
		$(foreach fs, $(or $2,$(BENCH_FSS)), \
			$(foreach sim, $(or $3, $(BENCH_SIMS)), \
				$(foreach bench, $4, \
					<(./scripts/csv.py \
						<(./scripts/csv.py \
							$(RESULTSDIR)/bench_$1_$(bench).$(fs).$(sim).csv \
							-fn \
							-fbench_readed \
							-fbench_proged \
							-fbench_erased \
							-Dbench_creaded='*' \
							-Dbench_cproged='*' \
							-Dbench_cerased='*' \
							-o-) \
						-bfs=$(fs) \
						-bsim=$(sim) \
						-bbench=$(bench) \
						-Dm=write,read \
						-DSIZE=$(shell python -c '$\
							print(max([$(P26_T_SIZES)]))') \
						-fthroughput=' \
							float(n) / max( \
								(float(bench_readed)*float(READ_TIME) \
									+ float(bench_proged)*float(PROG_TIME) \
									+ float(bench_erased)*float(ERASE_TIME) \
									) / 1.0e9, \
								1.0e-9)' \
						-fn \
						-ft=' \
							(float(bench_readed)*float(READ_TIME) \
								+ float(bench_proged)*float(PROG_TIME) \
								+ float(bench_erased)*float(ERASE_TIME) \
							) / 1.0e9' \
						-o-)))) \
		-I \
		-bfs \
		-bsim \
		-bbench \
		-Q)

# quick throughput ops recipe
#
# $1 - benchmark
# $2 - fs types/versions
# $3 - sim types
# $4 - benches
#
BENCH_T_RESULT_OPS_RECIPE = $(strip ./scripts/csv.py \
		$(foreach fs, $(or $2,$(BENCH_FSS)), \
			$(foreach sim, $(or $3,$(BENCH_SIMS)), \
				$(foreach bench, $4, \
					<(./scripts/csv.py \
						<(./scripts/csv.py \
							$(RESULTSDIR)/bench_$1_$(bench).$(fs).$(sim).csv \
							-fn \
							-fbench_readed \
							-fbench_proged \
							-fbench_erased \
							-Dbench_creaded='*' \
							-Dbench_cproged='*' \
							-Dbench_cerased='*' \
							-o-) \
						-bfs=$(fs) \
						-bsim=$(sim) \
						-bbench=$(bench) \
						-Dm=write,read \
						-DSIZE=$(shell python -c '$\
							print(max([$(P26_T_SIZES)]))') \
						-freaded=bench_readed \
						-fproged=bench_proged \
						-ferased=bench_erased \
						-o-)))) \
		-I \
		-bfs \
		-bsim \
		-bbench \
		-Q)

# quick throughput ram recipe
#
# $1 - benchmark
# $2 - fs types/versions
# $3 - sim types
# $4 - benches
#
BENCH_T_RESULT_RAM_RECIPE = $(strip ./scripts/csv.py \
		$(foreach fs, $(or $2,$(BENCH_FSS)), \
			$(foreach sim, $(or $3,$(BENCH_SIMS)), \
				$(foreach bench, $4, \
					<(./scripts/csv.py \
						<(./scripts/data.py $(BENCH_$(U_$(fs))_RUNNER) \
								-bfunction -o- \
							| $(BENCH_$(U_$(fs))_FILTER) \
							| ./scripts/csv.py - \
								-bfs=$(fs) \
								-bsim=$(sim) \
								-bbench=$(bench) \
								-bSIZE=all \
								-fdata=data_size \
								-o-) \
						<(./scripts/csv.py \
							$(RESULTSDIR)/bench_$1_$(bench).$(fs).$(sim).csv \
							-Dm=stack \
							-fstack=bench_readed \
							-fn \
							-Dbench_readed='*' \
							-Dbench_proged='*' \
							-Dbench_erased='*' \
							-Dbench_creaded='*' \
							-Dbench_cproged='*' \
							-Dbench_cerased='*' \
							-o-) \
						<(./scripts/csv.py \
							$(RESULTSDIR)/bench_$1_$(bench).$(fs).$(sim).csv \
							-Dm=heap \
							-fheap=bench_readed \
							-fn \
							-Dbench_readed='*' \
							-Dbench_proged='*' \
							-Dbench_erased='*' \
							-Dbench_creaded='*' \
							-Dbench_cproged='*' \
							-Dbench_cerased='*' \
							-o-) \
						-bfs=$(fs) \
						-bsim=$(sim) \
						-bbench=$(bench) \
						-DSIZE=all,$(shell python -c '$\
							print(max([$(P26_T_SIZES)]))') \
						-fdata \
						-fstack \
						-fheap \
						-ftotal='data+stack+heap' \
						-o-)))) \
		-I \
		-bfs \
		-bsim \
		-bbench \
		-Q)

## Quick write-throughput results
.PHONY: results-p26-wt
results-p26-wt:
	$(call BENCH_T_RESULT_RECIPE,$\
		p26_wt,$\
		$(BENCH_FSS),$\
		$(BENCH_SIMS),$\
		linear random many logging)

## Quick write-throughput ops
.PHONY: results-p26-wt-ops
results-p26-wt-ops:
	$(call BENCH_T_RESULT_OPS_RECIPE,$\
		p26_wt,$\
		$(BENCH_FSS),$\
		$(BENCH_SIMS),$\
		linear random many logging)

## Quick write-throughput ram
.PHONY: results-p26-wt-ram
results-p26-wt-ram:
	$(call BENCH_T_RESULT_RAM_RECIPE,$\
		p26_wt,$\
		$(BENCH_FSS),$\
		$(BENCH_SIMS),$\
		linear random many logging)

## Quick write-throughput results
.PHONY: results-p26-rt
results-p26-rt:
	$(call BENCH_T_RESULT_RECIPE,$\
		p26_rt,$\
		$(BENCH_FSS),$\
		$(BENCH_SIMS),$\
		linear random many)

## Quick write-throughput ops
.PHONY: results-p26-rt-ops
results-p26-rt-ops:
	$(call BENCH_T_RESULT_OPS_RECIPE,$\
		p26_rt,$\
		$(BENCH_FSS),$\
		$(BENCH_SIMS),$\
		linear random many)

# NOTE the way we measure ram includes the overhead of writing the
# initial filesystem, so rt-ram results is probably not useful as-is
#
### Quick write-throughput ram
#.PHONY: results-p26-rt-ram
#results-p26-rt-ram:
#	$(call BENCH_T_RESULT_RAM_RECIPE,$\
#		p26_rt,$\
#		$(BENCH_FSS),$\
#		$(BENCH_SIMS),$\
#		linear random many)


# simulated/estimated results
$(RESULTSDIR)/bench_%.sim.csv: $(RESULTSDIR)/bench_%.csv
	-$(strip ./scripts/csv.py $^ \
		-Bm='%(m)s+sim' \
		-fbench_readed=' \
			(float(bench_readed)*float(READ_TIME) \
				+ float(bench_proged)*float(PROG_TIME) \
				+ float(bench_erased)*float(ERASE_TIME) \
				) / 1.0e9' \
		-fbench_proged=0 \
		-fbench_erased=0 \
		-fbench_creaded=' \
			(float(bench_creaded)*float(READ_TIME) \
				+ float(bench_cproged)*float(PROG_TIME) \
				+ float(bench_cerased)*float(ERASE_TIME) \
				) / 1.0e9' \
		-fbench_cproged=0 \
		-fbench_cerased=0 \
		-o$@)

# simulated throughput results
#
# note we first sum n/readed/proged/erased
$(RESULTSDIR)/bench_%.tsim.csv: $(RESULTSDIR)/bench_%.csv
	-$(strip ./scripts/csv.py \
		<(./scripts/csv.py $^ \
			-fn \
			-fbench_readed \
			-fbench_proged \
			-fbench_erased \
			-Dbench_creaded='*' \
			-Dbench_cproged='*' \
			-Dbench_cerased='*' \
			-o-) \
		-Bm='%(m)s+tsim' \
		-fn \
		-fbench_readed=' \
			float(n) / max( \
				(float(bench_readed)*float(READ_TIME) \
					+ float(bench_proged)*float(PROG_TIME) \
					+ float(bench_erased)*float(ERASE_TIME) \
					) / 1.0e9, \
				1.0e-9)' \
		-fbench_proged=0 \
		-fbench_erased=0 \
		-o$@)

# simulated RAM results
#
# this includes stack + heap + any data sections
#
# $1 - target
# $2 - csv files
# $3 - fs type/version
#
define BENCH_P26_RAM_RULE
$1: $(BENCH_$(U_$3)_RUNNER) $2
	-$$(strip ./scripts/csv.py \
		<(./scripts/csv.py $$(wordlist 2,$$(words $$^),$$^) \
			-fn \
			-fbench_readed \
			-fbench_proged \
			-fbench_erased \
			-Dbench_creaded='*' \
			-Dbench_cproged='*' \
			-Dbench_cerased='*' \
			-o-) \
		-Dm=heap,stack \
		-Bm=ram \
		-fn \
		-fbench_readed="bench_readed + $$$$( \
			./scripts/data.py $$< -bfunction -o- \
				| $(BENCH_$(U_$3)_FILTER) \
				| ./scripts/csv.py - -fdata_size --total)" \
		-fbench_proged=0 \
		-fbench_erased=0 \
		-o$$@)
endef

$(foreach fs, $(BENCH_FSS),$\
	$(foreach sim, $(BENCH_SIMS),$\
		$(eval $(call BENCH_P26_RAM_RULE,$\
				$(RESULTSDIR)/bench_%.$(fs).$(sim).ram.csv,$\
				$(RESULTSDIR)/bench_%.$(fs).$(sim).csv,$\
				$(fs)))))

# amortized results
$(RESULTSDIR)/bench_%.amor.csv: $(RESULTSDIR)/bench_%.csv
	-$(strip ./scripts/csv.py $^ \
		-Bn -Bm='%(m)s+amor' \
		-fbench_readed='float(bench_creaded) / float(n)' \
		-fbench_proged='float(bench_cproged) / float(n)' \
		-fbench_erased='float(bench_cerased) / float(n)' \
		-o$@)

# per-byte/entry usage results
$(RESULTSDIR)/bench_%.per.csv: $(RESULTSDIR)/bench_%.csv
	-$(strip ./scripts/csv.py $^ \
		-Bn -Bm='%(m)s+per' \
		-Dbench_creaded='*' \
		-Dbench_cproged='*' \
		-Dbench_cerased='*' \
		-fbench_readed='float(bench_readed) / float(n)' \
		-fbench_proged='float(bench_proged) / float(n)' \
		-fbench_erased='float(bench_erased) / float(n)' \
		-o$@)

# averaged results (over SAMPLES)
$(RESULTSDIR)/bench_%.avg.csv: $(RESULTSDIR)/bench_%.csv
	-$(strip ./scripts/csv.py $^ \
		-DSEED='*' \
		-Dbench_creaded='*' \
		-Dbench_cproged='*' \
		-Dbench_cerased='*' \
		-fbench_readed_avg='avg(bench_readed)' \
		-fbench_proged_avg='avg(bench_proged)' \
		-fbench_erased_avg='avg(bench_erased)' \
		-fbench_readed_min='min(bench_readed)' \
		-fbench_proged_min='min(bench_proged)' \
		-fbench_erased_min='min(bench_erased)' \
		-fbench_readed_max='max(bench_readed)' \
		-fbench_proged_max='max(bench_proged)' \
		-fbench_erased_max='max(bench_erased)' \
		-o$@)




#======================================================================#
# and plotting rules, can't have benchmarks without plots!             #
#======================================================================#

# plot config
ifndef LIGHT
PLOTFLAGS += --dark
endif
ifdef GGPLOT
PLOTFLAGS += --ggplot
endif
ifdef XKCD
PLOTFLAGS += --xkcd
endif

# give specific filesystems explicit colors/shapes, to keep things
# consistent
ifdef LIGHT
# colors borrowed from Seaborn
# \#4c72b0bf # blue
# \#dd8452bf # orange
# \#55a868bf # green
# \#c44e52bf # red
# \#8172b3bf # purple
# \#937860bf # brown
# \#da8bc3bf # pink
# \#8c8c8cbf # gray
# \#ccb974bf # yellow
# \#64b5cdbf # cyan
C_lfs3   = \#4c72b0bf # blue
C_lfs3nb = \#dd8452bf # orange
C_lfs2   = \#55a868bf # green
C_spiffs = \#c44e52bf # red
C_yaffs2 = \#8172b3bf # purple
else
# colors borrowed from Seaborn
# \#a1c9f4bf # blue
# \#ffb482bf # orange
# \#8de5a1bf # green
# \#ff9f9bbf # red
# \#d0bbffbf # purple
# \#debb9bbf # brown
# \#fab0e4bf # pink
# \#cfcfcfbf # gray
# \#fffea3bf # yellow
# \#b9f2f0bf # cyan
C_lfs3   = \#a1c9f4bf # blue
C_lfs3nb = \#ffb482bf # orange
C_lfs2   = \#8de5a1bf # green
C_spiffs = \#ff9f9bbf # red
C_yaffs2 = \#d0bbffbf # purple
endif

F_lfs3	 = o # circle
F_lfs3nb = ^ # triangle
F_lfs2   = s # square
F_spiffs = X # big x
F_yaffs2 = P # big plus


# overrideable plot rules
PLOT_RULES ?= \
		plot-p26-litmus \
		plot-p26-wt \
		plot-p26-rt

## Plot all benchmarks!
.PHONY: plot plot-all
plot plot-all: $(PLOT_RULES)

## Plot p26 litmus benchmarks
.PHONY: plot-p26-litmus
plot-p26-litmus: \
		plot-p26-litmus-litmus \
		plot-p26-litmus-ops

## Plot p26 litmus litmus benchmarks
.PHONY: plot-p26-litmus-litmus
plot-p26-litmus-litmus: \
		plot-p26-litmus-linear \
		plot-p26-litmus-random \
		plot-p26-litmus-many \
		plot-p26-litmus-logging

## Plot p26 litmus linear benchmarks
.PHONY: plot-p26-litmus-linear
plot-p26-litmus-linear: \
		$(PLOTSDIR)/bench_p26_litmus_linear.svg

## Plot p26 litmus random benchmarks
.PHONY: plot-p26-litmus-random
plot-p26-litmus-random: \
		$(PLOTSDIR)/bench_p26_litmus_random.svg

## Plot p26 litmus many benchmarks
.PHONY: plot-p26-litmus-many
plot-p26-litmus-many: \
		$(PLOTSDIR)/bench_p26_litmus_many.svg

## Plot p26 litmus logging benchmarks
.PHONY: plot-p26-litmus-logging
plot-p26-litmus-logging: \
		$(PLOTSDIR)/bench_p26_litmus_logging.svg

## Plot p26 litmus ops benchmarks
.PHONY: plot-p26-litmus-ops
plot-p26-litmus-ops: \
		plot-p26-litmus-ops-linear \
		plot-p26-litmus-ops-random \
		plot-p26-litmus-ops-many \
		plot-p26-litmus-ops-logging

## Plot p26 litmus ops linear benchmarks
.PHONY: plot-p26-litmus-ops-linear
plot-p26-litmus-ops-linear: \
		$(PLOTSDIR)/bench_p26_litmus_linear_r.svg \
		$(PLOTSDIR)/bench_p26_litmus_linear_p.svg \
		$(PLOTSDIR)/bench_p26_litmus_linear_e.svg \
		$(PLOTSDIR)/bench_p26_litmus_linear_u.svg \
		$(PLOTSDIR)/bench_p26_litmus_linear_s.svg \
		$(PLOTSDIR)/bench_p26_litmus_linear_h.svg

## Plot p26 litmus ops random benchmarks
.PHONY: plot-p26-litmus-ops-random
plot-p26-litmus-ops-random: \
		$(PLOTSDIR)/bench_p26_litmus_random_r.svg \
		$(PLOTSDIR)/bench_p26_litmus_random_p.svg \
		$(PLOTSDIR)/bench_p26_litmus_random_e.svg \
		$(PLOTSDIR)/bench_p26_litmus_random_u.svg \
		$(PLOTSDIR)/bench_p26_litmus_random_s.svg \
		$(PLOTSDIR)/bench_p26_litmus_random_h.svg

## Plot p26 litmus ops many benchmarks
.PHONY: plot-p26-litmus-ops-many
plot-p26-litmus-ops-many: \
		$(PLOTSDIR)/bench_p26_litmus_many_r.svg \
		$(PLOTSDIR)/bench_p26_litmus_many_p.svg \
		$(PLOTSDIR)/bench_p26_litmus_many_e.svg \
		$(PLOTSDIR)/bench_p26_litmus_many_u.svg \
		$(PLOTSDIR)/bench_p26_litmus_many_s.svg \
		$(PLOTSDIR)/bench_p26_litmus_many_h.svg

## Plot p26 litmus ops logging benchmarks
.PHONY: plot-p26-litmus-ops-logging
plot-p26-litmus-ops-logging: \
		$(PLOTSDIR)/bench_p26_litmus_logging_r.svg \
		$(PLOTSDIR)/bench_p26_litmus_logging_p.svg \
		$(PLOTSDIR)/bench_p26_litmus_logging_e.svg \
		$(PLOTSDIR)/bench_p26_litmus_logging_u.svg \
		$(PLOTSDIR)/bench_p26_litmus_logging_s.svg \
		$(PLOTSDIR)/bench_p26_litmus_logging_h.svg

## Plot p26 write-throughput benchmarks
.PHONY: plot-p26-wt
plot-p26-wt: \
		plot-p26-wt-wt \
		plot-p26-wt-usage \
		plot-p26-wt-stack \
		plot-p26-wt-heap \
		plot-p26-wt-ram

## Plot p26 write-throughput write-throughput benchmarks
.PHONY: plot-p26-wt-wt
plot-p26-wt-wt: \
		plot-p26-wt-linear \
		plot-p26-wt-random \
		plot-p26-wt-many \
		plot-p26-wt-logging

## Plot p26 write-throughput linear benchmarks
.PHONY: plot-p26-wt-linear
plot-p26-wt-linear: \
		$(PLOTSDIR)/bench_p26_wt_linear.svg

## Plot p26 write-throughput random benchmarks
.PHONY: plot-p26-wt-random
plot-p26-wt-random: \
		$(PLOTSDIR)/bench_p26_wt_random.svg

## Plot p26 write-throughput many benchmarks
.PHONY: plot-p26-wt-many
plot-p26-wt-many: \
		$(PLOTSDIR)/bench_p26_wt_many.svg

## Plot p26 write-throughput logging benchmarks
.PHONY: plot-p26-wt-logging
plot-p26-wt-logging: \
		$(PLOTSDIR)/bench_p26_wt_logging.svg

## Plot p26 read-throughput benchmarks
.PHONY: plot-p26-rt
plot-p26-rt: \
		plot-p26-rt-rt

## Plot p26 read-throughput read-throughput benchmarks
.PHONY: plot-p26-rt-rt
plot-p26-rt-rt: \
		plot-p26-rt-linear \
		plot-p26-rt-random \
		plot-p26-rt-many

## Plot p26 read-throughput linear benchmarks
.PHONY: plot-p26-rt-linear
plot-p26-rt-linear: \
		$(PLOTSDIR)/bench_p26_rt_linear.svg

## Plot p26 read-throughput random benchmarks
.PHONY: plot-p26-rt-random
plot-p26-rt-random: \
		$(PLOTSDIR)/bench_p26_rt_random.svg

## Plot p26 read-throughput many benchmarks
.PHONY: plot-p26-rt-many
plot-p26-rt-many: \
		$(PLOTSDIR)/bench_p26_rt_many.svg

## Plot p26 write-throughput usage benchmarks
.PHONY: plot-p26-wt-usage
plot-p26-wt-usage: \
		plot-p26-wt-usage-linear \
		plot-p26-wt-usage-random \
		plot-p26-wt-usage-many \
		plot-p26-wt-usage-logging

## Plot p26 write-throughput usage linear benchmarks
.PHONY: plot-p26-wt-usage-linear
plot-p26-wt-usage-linear: \
		$(PLOTSDIR)/bench_p26_wt_usage_linear.svg

## Plot p26 write-throughput usage random benchmarks
.PHONY: plot-p26-wt-usage-random
plot-p26-wt-usage-random: \
		$(PLOTSDIR)/bench_p26_wt_usage_random.svg

## Plot p26 write-throughput usage many benchmarks
.PHONY: plot-p26-wt-usage-many
plot-p26-wt-usage-many: \
		$(PLOTSDIR)/bench_p26_wt_usage_many.svg

## Plot p26 write-throughput usage logging benchmarks
.PHONY: plot-p26-wt-usage-logging
plot-p26-wt-usage-logging: \
		$(PLOTSDIR)/bench_p26_wt_usage_logging.svg

## Plot p26 write-throughput stack benchmarks
.PHONY: plot-p26-wt-stack
plot-p26-wt-stack: \
		plot-p26-wt-stack-linear \
		plot-p26-wt-stack-random \
		plot-p26-wt-stack-many \
		plot-p26-wt-stack-logging

## Plot p26 write-throughput stack linear benchmarks
.PHONY: plot-p26-wt-stack-linear
plot-p26-wt-stack-linear: \
		$(PLOTSDIR)/bench_p26_wt_stack_linear.svg

## Plot p26 write-throughput stack random benchmarks
.PHONY: plot-p26-wt-stack-random
plot-p26-wt-stack-random: \
		$(PLOTSDIR)/bench_p26_wt_stack_random.svg

## Plot p26 write-throughput stack many benchmarks
.PHONY: plot-p26-wt-stack-many
plot-p26-wt-stack-many: \
		$(PLOTSDIR)/bench_p26_wt_stack_many.svg

## Plot p26 write-throughput stack logging benchmarks
.PHONY: plot-p26-wt-stack-logging
plot-p26-wt-stack-logging: \
		$(PLOTSDIR)/bench_p26_wt_stack_logging.svg

## Plot p26 write-throughput heap benchmarks
.PHONY: plot-p26-wt-heap
plot-p26-wt-heap: \
		plot-p26-wt-heap-linear \
		plot-p26-wt-heap-random \
		plot-p26-wt-heap-many \
		plot-p26-wt-heap-logging

## Plot p26 write-throughput heap linear benchmarks
.PHONY: plot-p26-wt-heap-linear
plot-p26-wt-heap-linear: \
		$(PLOTSDIR)/bench_p26_wt_heap_linear.svg

## Plot p26 write-throughput heap random benchmarks
.PHONY: plot-p26-wt-heap-random
plot-p26-wt-heap-random: \
		$(PLOTSDIR)/bench_p26_wt_heap_random.svg

## Plot p26 write-throughput heap many benchmarks
.PHONY: plot-p26-wt-heap-many
plot-p26-wt-heap-many: \
		$(PLOTSDIR)/bench_p26_wt_heap_many.svg

## Plot p26 write-throughput heap logging benchmarks
.PHONY: plot-p26-wt-heap-logging
plot-p26-wt-heap-logging: \
		$(PLOTSDIR)/bench_p26_wt_heap_logging.svg

## Plot p26 write-throughput ram benchmarks
.PHONY: plot-p26-wt-ram
plot-p26-wt-ram: \
		plot-p26-wt-ram-linear \
		plot-p26-wt-ram-random \
		plot-p26-wt-ram-many \
		plot-p26-wt-ram-logging

## Plot p26 write-throughput ram linear benchmarks
.PHONY: plot-p26-wt-ram-linear
plot-p26-wt-ram-linear: \
		$(PLOTSDIR)/bench_p26_wt_ram_linear.svg

## Plot p26 write-throughput ram random benchmarks
.PHONY: plot-p26-wt-ram-random
plot-p26-wt-ram-random: \
		$(PLOTSDIR)/bench_p26_wt_ram_random.svg

## Plot p26 write-throughput ram many benchmarks
.PHONY: plot-p26-wt-ram-many
plot-p26-wt-ram-many: \
		$(PLOTSDIR)/bench_p26_wt_ram_many.svg

## Plot p26 write-throughput ram logging benchmarks
.PHONY: plot-p26-wt-ram-logging
plot-p26-wt-ram-logging: \
		$(PLOTSDIR)/bench_p26_wt_ram_logging.svg




# p26 plot rules!

# p26 litmus plot rule
#
# $1 - target
# $2 - sources
# $3 - title
# $4 - y field
# $5 - measurement
# $6 - optional amor/per flag
# $7 - extra plotmpl.py flags
#
define PLOT_P26_LITMUS_RULE
$1: $2
	$$(strip ./scripts/plotmpl.py \
		<(./scripts/csv.py $$^ \
			-f$4_avg \
			-f$4_bnd=$4_min \
			-o-) \
		<(./scripts/csv.py $$^ \
			-D$4_avg='*' \
			-f$4_bnd=$4_max \
			-o-) \
		-W1500 -H700 \
		--title=$3 \
		-bFS \
		-xn \
		-y$4_avg -y$4_bnd \
		--subplot=" \
				-DERASE_SIZE='$($(U_$(firstword $(BENCH_SIMS)))_ERASE_SIZE)' \
				-Dm=$5 \
				$(if $(filter amor,$6),--ylabel=raw) \
				$(if $(filter per,$6),--ylabel=total) \
				--title=$(firstword $(BENCH_SIMS)) \
				$(if $6,--add-xticklabel=,) \
				--ylim-ratio=0.98" \
			$(if $6, \
			--subplot-below=" \
				-DERASE_SIZE='$($(U_$(firstword $(BENCH_SIMS)))_ERASE_SIZE)' \
				-Dm=$5+$6 \
				$(if $(filter amor,$6),--ylabel=amortized) \
				$(if $(filter per,$6),--ylabel=per) \
				--ylim-ratio=0.98 \
				-H0.5",) \
		$(foreach sim, $(wordlist 2,$(words $(BENCH_SIMS)),$(BENCH_SIMS)),$\
			--subplot-right=" \
					-DERASE_SIZE='$($(U_$(sim))_ERASE_SIZE)' \
					-Dm=$5 \
					--title=$(sim) \
					$(if $6,--add-xticklabel=,) \
					--ylim-ratio=0.98 \
					-W$$(shell python -c '$\
						print(1 / ($\
							"$(BENCH_SIMS)".split()$\
								.index("$(sim)")+1))') \
				$(if $6, \
				--subplot-below=\" \
					-DERASE_SIZE='$($(U_$(sim))_ERASE_SIZE)' \
					-Dm=$5+$6 \
					--ylim-ratio=0.98 \
					-H0.5\",)") \
		--legend \
		$(foreach fs, $(BENCH_FSS),$\
			-L'$(N_$(fs)),$4_avg=$(fs)%n$\
				- bs=$(EMMC_$(U_$(fs))_BLOCK_SIZE)%n$\
				- bs=$(NOR_$(U_$(fs))_BLOCK_SIZE)%n$\
				- bs=$(NAND_$(U_$(fs))_BLOCK_SIZE)' \
			-L'$(N_$(fs)),$4_bnd=') \
		$(foreach fs, $(BENCH_FSS),$\
			-C'$(N_$(fs)),$4_avg=$(C_$(fs))') \
		$(foreach fs, $(BENCH_FSS),$\
			-C'$(N_$(fs)),$4_bnd=$(C_$(fs):bf=1f)') \
		$7 \
		$$(PLOTFLAGS) \
		-o$$@)
endef

$(eval $(call PLOT_P26_LITMUS_RULE,$\
		$(PLOTSDIR)/bench_p26_litmus_%_r.svg,$\
		$(foreach fs, $(BENCH_FSS),$\
			$(foreach sim, $(BENCH_SIMS),$\
				$(RESULTSDIR)/bench_p26_litmus_%.$(fs).$(sim).avg.csv $\
				$(RESULTSDIR)/bench_p26_litmus_%.$(fs).$(sim).amor.avg.csv)),$\
		"$$* file writes - reads",$\
		bench_readed,$\
		write,$\
		amor,$\
		-DMODE=0 --x2 --xunits=B --y2 --yunits=B))
$(eval $(call PLOT_P26_LITMUS_RULE,$\
		$(PLOTSDIR)/bench_p26_litmus_%_p.svg,$\
		$(foreach fs, $(BENCH_FSS),$\
			$(foreach sim, $(BENCH_SIMS),$\
				$(RESULTSDIR)/bench_p26_litmus_%.$(fs).$(sim).avg.csv $\
				$(RESULTSDIR)/bench_p26_litmus_%.$(fs).$(sim).amor.avg.csv)),$\
		"$$* file writes - progs",$\
		bench_proged,$\
		write,$\
		amor,$\
		-DMODE=0 --x2 --xunits=B --y2 --yunits=B))
$(eval $(call PLOT_P26_LITMUS_RULE,$\
		$(PLOTSDIR)/bench_p26_litmus_%_e.svg,$\
		$(foreach fs, $(BENCH_FSS),$\
			$(foreach sim, $(BENCH_SIMS),$\
				$(RESULTSDIR)/bench_p26_litmus_%.$(fs).$(sim).avg.csv $\
				$(RESULTSDIR)/bench_p26_litmus_%.$(fs).$(sim).amor.avg.csv)),$\
		"$$* file writes - erases",$\
		bench_erased,$\
		write,$\
		amor,$\
		-DMODE=0 --x2 --xunits=B --y2 --yunits=B))
$(eval $(call PLOT_P26_LITMUS_RULE,$\
		$(PLOTSDIR)/bench_p26_litmus_%_u.svg,$\
		$(foreach fs, $(BENCH_FSS),$\
			$(foreach sim, $(BENCH_SIMS),$\
				$(RESULTSDIR)/bench_p26_litmus_%.$(fs).$(sim).avg.csv $\
				$(RESULTSDIR)/bench_p26_litmus_%.$(fs).$(sim).per.avg.csv)),$\
		"$$* file disk usage",$\
		bench_readed,$\
		usage,$\
		per,$\
		-DMODE=1 --x2 --xunits=B --y2 --yunits=B))
$(eval $(call PLOT_P26_LITMUS_RULE,$\
		$(PLOTSDIR)/bench_p26_litmus_%_s.svg,$\
		$(foreach fs, $(BENCH_FSS),$\
			$(foreach sim, $(BENCH_SIMS),$\
				$(RESULTSDIR)/bench_p26_litmus_%.$(fs).$(sim).avg.csv $\
				$(RESULTSDIR)/bench_p26_litmus_%.$(fs).$(sim).per.avg.csv)),$\
		"$$* file stack usage",$\
		bench_readed,$\
		stack,$\
		per,$\
		-DMODE=2 --x2 --xunits=B --y2 --yunits=B))
$(eval $(call PLOT_P26_LITMUS_RULE,$\
		$(PLOTSDIR)/bench_p26_litmus_%_h.svg,$\
		$(foreach fs, $(BENCH_FSS),$\
			$(foreach sim, $(BENCH_SIMS),$\
				$(RESULTSDIR)/bench_p26_litmus_%.$(fs).$(sim).avg.csv $\
				$(RESULTSDIR)/bench_p26_litmus_%.$(fs).$(sim).per.avg.csv)),$\
		"$$* file heap usage",$\
		bench_readed,$\
		heap,$\
		per,$\
		-DMODE=2 --x2 --xunits=B --y2 --yunits=B))
$(eval $(call PLOT_P26_LITMUS_RULE,$\
		$(PLOTSDIR)/bench_p26_litmus_%.svg,$\
		$(foreach fs, $(BENCH_FSS),$\
			$(foreach sim, $(BENCH_SIMS),$\
				$(RESULTSDIR)/bench_p26_litmus_%$\
					.$(fs).$(sim).sim.avg.csv $\
				$(RESULTSDIR)/bench_p26_litmus_%$\
					.$(fs).$(sim).sim.amor.avg.csv)),$\
		"$$* file writes - simulated runtime",$\
		bench_readed,$\
		write+sim,$\
		amor,$\
		-DMODE=0 --x2 --xunits=B --yunits=s))

# p26 throughput plot rule
#
# $1 - target
# $2 - sources
# $3 - title
# $4 - x-axis
# $5 - x-ticks
# $6 - measurement
# $7 - extra plotmpl.py flags
#
define PLOT_P26_T_RULE
$1: $2
	$$(strip ./scripts/plotmpl.py $$^ \
		-W1500 -H350 \
		--title=$3 \
		-bFS \
		-x$4 \
		-ybench_readed \
		-Dm=$6 \
		--subplot=" \
			-DERASE_SIZE=$($(U_$(firstword $(BENCH_SIMS)))_ERASE_SIZE) \
			--title=$(firstword $(BENCH_SIMS))" \
		$(foreach sim, $(wordlist 2,$(words $(BENCH_SIMS)),$(BENCH_SIMS)),$\
			--subplot-right=" \
				-DERASE_SIZE=$($(U_$(sim))_ERASE_SIZE) \
				--title=$(sim) \
				-W$$(shell python -c '$\
					print(1 / ($\
						"$(BENCH_SIMS)".split()$\
							.index("$(sim)")+1))')") \
		--legend \
		$(foreach fs, $(BENCH_FSS),$\
			-L'$(N_$(fs))=$(fs)') \
		$(foreach fs, $(BENCH_FSS),$\
			-C'$(N_$(fs))=$(C_$(fs))') \
		$(foreach fs, $(BENCH_FSS),$\
			-F'$(N_$(fs))=$(addsuffix -,$(F_$(fs)))') \
		--xlog \
		--xticks=4 \
		-X"$$(shell python -c 'a=min([$5]); print(a-a/4)'),$\
			$$(shell python -c 'b=max([$5]); print(b+b/4)')" \
		--x2 --xunits=B \
		--y2 --yunits=B/s \
		$$(shell python -c '$\
			for n in [$5]: $\
				print("--add-xticklabel=%d=\"%%(x)IB\"" % n)') \
		$7 \
		$$(PLOTFLAGS) \
		-o$$@)
endef

# p26 throughput plot rules
$(eval $(call PLOT_P26_T_RULE,$\
		$(PLOTSDIR)/bench_p26_wt_%.svg,$\
		$(foreach fs, $(BENCH_FSS),$\
			$(foreach sim, $(BENCH_SIMS),$\
				$(RESULTSDIR)/bench_p26_wt_%.$(fs).$(sim).tsim.csv)),$\
		"$$* file writes - simulated throughput",$\
		SIZE,$\
		$(P26_T_SIZES),$\
		write+tsim,$\
		--y2 --yunits=B/s))

$(eval $(call PLOT_P26_T_RULE,$\
		$(PLOTSDIR)/bench_p26_rt_%.svg,$\
		$(foreach fs, $(BENCH_FSS),$\
			$(foreach sim, $(BENCH_SIMS),$\
				$(RESULTSDIR)/bench_p26_rt_%.$(fs).$(sim).tsim.csv)),$\
		"$$* file reads - simulated throughput",$\
		SIZE,$\
		$(P26_T_SIZES),$\
		read+tsim,$\
		--y2 --yunits=B/s))

# p26 throughput usage rules
$(eval $(call PLOT_P26_T_RULE,$\
		$(PLOTSDIR)/bench_p26_wt_usage_%.svg,$\
		$(foreach fs, $(BENCH_FSS),$\
			$(foreach sim, $(BENCH_SIMS),$\
				$(RESULTSDIR)/bench_p26_wt_%.$(fs).$(sim).csv)),$\
		"$$* file writes - disk usage",$\
		SIZE,$\
		$(P26_T_SIZES),$\
		usage,$\
		--y2 --yunits=B))

# p26 throughput stack rules
$(eval $(call PLOT_P26_T_RULE,$\
		$(PLOTSDIR)/bench_p26_wt_stack_%.svg,$\
		$(foreach fs, $(BENCH_FSS),$\
			$(foreach sim, $(BENCH_SIMS),$\
				$(RESULTSDIR)/bench_p26_wt_%.$(fs).$(sim).csv)),$\
		"$$* file writes - stack usage",$\
		SIZE,$\
		$(P26_T_SIZES),$\
		stack,$\
		--y2 --yunits=B))

# p26 throughput heap rules
$(eval $(call PLOT_P26_T_RULE,$\
		$(PLOTSDIR)/bench_p26_wt_heap_%.svg,$\
		$(foreach fs, $(BENCH_FSS),$\
			$(foreach sim, $(BENCH_SIMS),$\
				$(RESULTSDIR)/bench_p26_wt_%.$(fs).$(sim).csv)),$\
		"$$* file writes - heap usage",$\
		SIZE,$\
		$(P26_T_SIZES),$\
		heap,$\
		--y2 --yunits=B))

# p26 throughput ram rules
$(eval $(call PLOT_P26_T_RULE,$\
		$(PLOTSDIR)/bench_p26_wt_ram_%.svg,$\
		$(foreach fs, $(BENCH_FSS),$\
			$(foreach sim, $(BENCH_SIMS),$\
				$(RESULTSDIR)/bench_p26_wt_%.$(fs).$(sim).ram.csv)),$\
		"$$* file writes - RAM usage",$\
		SIZE,$\
		$(P26_T_SIZES),$\
		ram,$\
		--y2 --yunits=B))




#======================================================================#
# tikz rules, these just compile results for tikz consumption          #
#======================================================================#

# overrideable tikz rules
TIKZ_RULES ?= \
		tikz-p26-wt

## Generate all tikzs!
.PHONY: tikz tikz-all
tikz tikz-all: $(TIKZ_RULES)

## Generate write-throughput tikz results
.PHONY: tikz-p26-wt
tikz-p26-wt: \
		$(TIKZDIR)/tikz_p26_wt.csv \
		$(foreach sim, $(BENCH_SIMS),$\
			$(foreach bench, linear random many logging,$\
				$(TIKZDIR)/tikz_p26_wt_$(sim)_$(bench).csv)) \
		$(TIKZDIR)/tikz_p26_wt_ops.csv \
		$(foreach sim, $(BENCH_SIMS),$\
			$(foreach bench, linear random many logging,$\
				$(TIKZDIR)/tikz_p26_wt_ops_$(sim)_$(bench).csv)) \
		$(TIKZDIR)/tikz_p26_wt_ram.csv \
		$(foreach sim, $(BENCH_SIMS),$\
			$(foreach bench, linear random many logging,$\
				$(TIKZDIR)/tikz_p26_wt_ram_$(sim)_$(bench).csv)) \
		$(foreach sim, $(BENCH_SIMS),$\
			$(TIKZDIR)/tikz_p26_wt_ram_$(sim).csv)

# write-throughput tikz results
$(TIKZDIR)/tikz_p26_wt.csv: \
		$(foreach fs, $(BENCH_FSS), \
			$(foreach sim, $(BENCH_SIMS), \
				$(foreach bench, linear random many logging, \
					$(RESULTSDIR)/bench_p26_wt_$(bench).$\
						$(fs).$(sim).csv)))
	$(strip ./scripts/csv.py \
		$(foreach fs, $(BENCH_FSS), \
			$(foreach sim, $(BENCH_SIMS), \
				$(foreach bench, linear random many logging, \
					<(./scripts/csv.py \
						<(./scripts/csv.py \
							$(RESULTSDIR)/bench_p26_wt_$(bench).$\
								$(fs).$(sim).csv \
							-fn \
							-fbench_readed \
							-fbench_proged \
							-fbench_erased \
							-Dbench_creaded='*' \
							-Dbench_cproged='*' \
							-Dbench_cerased='*' \
							-o-) \
						-bfs=$(fs) \
						-bsim=$(sim) \
						-bbench=$(bench) \
						-Dm=write,read \
						-DSIZE=$(shell python -c '$\
							print(max([$(P26_T_SIZES)]))') \
						-fthroughput=' \
							float(n) / max( \
								(float(bench_readed)*float(READ_TIME) \
									+ float(bench_proged)*float(PROG_TIME) \
									+ float(bench_erased)*float(ERASE_TIME) \
									) / 1.0e9, \
								1.0e-9)' \
						-fn \
						-ft=' \
							(float(bench_readed)*float(READ_TIME) \
								+ float(bench_proged)*float(PROG_TIME) \
								+ float(bench_erased)*float(ERASE_TIME) \
							) / 1.0e9' \
						-o-)))) \
		-bfs \
		-bsim \
		-bbench \
		-o$@)

# tikz write-throughput transposition rule
#
# $1 - target
# $2 - source
# $3 - sim
# $4 - bench
#
define TIKZ_T_WT_RULE
$1: $2
	$$(strip ./scripts/csv.py \
		$(foreach fs,$(BENCH_FSS),$\
			<(./scripts/csv.py $$^ \
				-bsim -Dsim=$3 \
				-bbench -Dbench=$4 \
				-Dfs=$(fs) \
				-f$(fs)=throughput \
				-o-)) \
		-bsim \
		-bbench \
		-o$$@)
endef

$(foreach sim, $(BENCH_SIMS),$\
	$(foreach bench, linear random many logging,$\
		$(eval $(call TIKZ_T_WT_RULE,$\
			$(TIKZDIR)/tikz_p26_wt_$(sim)_$(bench).csv,$\
			$(TIKZDIR)/tikz_p26_wt.csv,$\
			$(sim),$\
			$(bench)))))

# write-throughput per-n ops tikz results
$(TIKZDIR)/tikz_p26_wt_ops.csv: \
		$(foreach fs, $(BENCH_FSS), \
			$(foreach sim, $(BENCH_SIMS), \
				$(foreach bench, linear random many logging, \
					$(RESULTSDIR)/bench_p26_wt_$(bench).$\
						$(fs).$(sim).csv)))
	$(strip ./scripts/csv.py \
		$(foreach fs, $(BENCH_FSS), \
			$(foreach sim, $(BENCH_SIMS), \
				$(foreach bench, linear random many logging, \
					<(./scripts/csv.py \
						<(./scripts/csv.py \
							$(RESULTSDIR)/bench_p26_wt_$(bench).$\
								$(fs).$(sim).csv \
							-fn \
							-fbench_readed \
							-fbench_proged \
							-fbench_erased \
							-Dbench_creaded='*' \
							-Dbench_cproged='*' \
							-Dbench_cerased='*' \
							-o-) \
						-bfs=$(fs) \
						-bsim=$(sim) \
						-bbench=$(bench) \
						-Dm=write,read \
						-DSIZE=$(shell python -c '$\
							print(max([$(P26_T_SIZES)]))') \
						-freaded='float(bench_readed) $\
							/ (float(n)/float(SIZE))' \
						-fproged='float(bench_proged) $\
							/ (float(n)/float(SIZE))' \
						-ferased='float(bench_erased) $\
							/ (float(n)/float(SIZE))' \
						-freadtime='float(READ_TIME) * float(bench_readed) $\
							/ (float(n)/float(SIZE))' \
						-fprogtime='float(PROG_TIME) * float(bench_proged) $\
							/ (float(n)/float(SIZE))' \
						-ferasetime='float(ERASE_TIME) * float(bench_erased) $\
							/ (float(n)/float(SIZE))' \
						-fnorm_readed='float(bench_readed) $\
							/ (float(bench_readed) $\
								+ float(bench_proged) $\
								+ float(bench_erased))' \
						-fnorm_proged='float(bench_proged) $\
							/ (float(bench_readed) $\
								+ float(bench_proged) $\
								+ float(bench_erased))' \
						-fnorm_erased='float(bench_erased) $\
							/ (float(bench_readed) $\
								+ float(bench_proged) $\
								+ float(bench_erased))' \
						-fnorm_readtime='$\
							(float(READ_TIME) * float(bench_readed)) $\
								/ (float(READ_TIME)*float(bench_readed) $\
									+ float(PROG_TIME)*float(bench_proged) $\
									+ float(ERASE_TIME)*float(bench_erased))' \
						-fnorm_progtime='$\
							(float(PROG_TIME) * float(bench_proged)) $\
								/ (float(READ_TIME)*float(bench_readed) $\
									+ float(PROG_TIME)*float(bench_proged) $\
									+ float(ERASE_TIME)*float(bench_erased))' \
						-fnorm_erasetime='$\
							(float(ERASE_TIME) * float(bench_erased)) $\
								/ (float(READ_TIME)*float(bench_readed) $\
									+ float(PROG_TIME)*float(bench_proged) $\
									+ float(ERASE_TIME)*float(bench_erased))' \
						-o-)))) \
		-bfs \
		-bsim \
		-bbench \
		-o$@)

# tikz write-throughput per-n ops transposition rule
#
# $1 - target
# $2 - source
# $3 - sim
# $4 - bench
#
define TIKZ_T_WT_OPS_RULE
$1: $2
	$$(strip ./scripts/csv.py $$^ \
		-bsim -Dsim=$3 \
		-bbench -Dbench=$4 \
		-bfs \
		-o$$@)
endef

$(foreach sim, $(BENCH_SIMS),$\
	$(foreach bench, linear random many logging,$\
		$(eval $(call TIKZ_T_WT_OPS_RULE,$\
			$(TIKZDIR)/tikz_p26_wt_ops_$(sim)_$(bench).csv,$\
			$(TIKZDIR)/tikz_p26_wt_ops.csv,$\
			$(sim),$\
			$(bench)))))

# write-throughput per-n ram tikz results
$(TIKZDIR)/tikz_p26_wt_ram.csv: \
		$(foreach fs, $(BENCH_FSS), \
			$(foreach sim, $(BENCH_SIMS), \
				$(foreach bench, linear random many logging, \
					$(RESULTSDIR)/bench_p26_wt_$(bench).$\
						$(fs).$(sim).csv)))
	$(strip ./scripts/csv.py \
		$(foreach fs, $(BENCH_FSS), \
			$(foreach sim, $(BENCH_SIMS), \
				$(foreach bench, linear random many logging, \
					<(./scripts/csv.py \
						<(./scripts/data.py $(BENCH_$(U_$(fs))_RUNNER) \
								-bfunction -o- \
							| $(BENCH_$(U_$(fs))_FILTER) \
							| ./scripts/csv.py - \
								-bfs=$(fs) \
								-bsim=$(sim) \
								-bbench=$(bench) \
								-bSIZE=all \
								-fdata=data_size \
								-o-) \
						<(./scripts/csv.py \
							$(RESULTSDIR)/bench_p26_wt_$(bench)$\
								.$(fs).$(sim).csv \
							-Dm=stack \
							-fstack=bench_readed \
							-fn \
							-Dbench_readed='*' \
							-Dbench_proged='*' \
							-Dbench_erased='*' \
							-Dbench_creaded='*' \
							-Dbench_cproged='*' \
							-Dbench_cerased='*' \
							-o-) \
						<(./scripts/csv.py \
							$(RESULTSDIR)/bench_p26_wt_$(bench)$\
								.$(fs).$(sim).csv \
							-Dm=heap \
							-fheap=bench_readed \
							-fn \
							-Dbench_readed='*' \
							-Dbench_proged='*' \
							-Dbench_erased='*' \
							-Dbench_creaded='*' \
							-Dbench_cproged='*' \
							-Dbench_cerased='*' \
							-o-) \
						-bfs=$(fs) \
						-bsim=$(sim) \
						-bbench=$(bench) \
						-DSIZE=all,$(shell python -c '$\
							print(max([$(P26_T_SIZES)]))') \
						-fdata \
						-fstack \
						-fheap \
						-fram=data+stack+heap \
						-o-)))) \
		-bfs \
		-bsim \
		-bbench \
		-o$@)

# tikz write-throughput per-n ram transposition rule
#
# $1 - target
# $2 - source
# $3 - sim
# $4 - bench
#
define TIKZ_T_WT_RAM_RULE
$1: $2
	$$(strip ./scripts/csv.py \
		$(foreach fs,$(BENCH_FSS),$\
			<(./scripts/csv.py $$^ \
				-bsim -Dsim=$3 \
				-bbench $(if $4,-Dbench=$4) \
				-Dfs=$(fs) \
				-f$(fs)=ram \
				-o-)) \
		-bsim \
		-bbench \
		-o$$@)
endef

$(foreach sim, $(BENCH_SIMS),$\
	$(foreach bench, linear random many logging,$\
		$(eval $(call TIKZ_T_WT_RAM_RULE,$\
			$(TIKZDIR)/tikz_p26_wt_ram_$(sim)_$(bench).csv,$\
			$(TIKZDIR)/tikz_p26_wt_ram.csv,$\
			$(sim),$\
			$(bench)))))

$(foreach sim, $(BENCH_SIMS),$\
	$(eval $(call TIKZ_T_WT_RAM_RULE,$\
		$(TIKZDIR)/tikz_p26_wt_ram_$(sim).csv,$\
		$(TIKZDIR)/tikz_p26_wt_ram.csv,$\
		$(sim))))






#======================================================================#
# cleaning rules, we put everything in build dirs, so this is easy     #
#======================================================================#

## Clean everything
.PHONY: clean
clean: \
		clean-build \
		clean-codemaps \
		clean-tikz \
		clean-results \
		clean-plots

## Clean bench-runner things
.PHONY: clean-build
clean-build:
	rm -rf $(BUILDDIR)

## Clean codemaps
.PHONY: clean-codemaps
clean-codemaps:
	rm -rf $(CODEMAPSDIR)

## Clean tikz
.PHONY: clean-tikz
clean-tikz:
	rm -rf $(TIKZDIR)

## Clean bench results
.PHONY: clean-results
clean-results:
	rm -rf $(RESULTSDIR)

## Clean bench plots
.PHONY: clean-plots
clean-plots:
	rm -rf $(PLOTSDIR)

