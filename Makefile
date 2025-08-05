# overrideable build dir, default to ./build
BUILDDIR ?= build
# overrideable results dir, default to ./results
RESULTSDIR ?= results
# overrideable codemaps dir, defaults to ./codemaps
CODEMAPSDIR ?= codemaps
# overrideable plots dir, defaults ./plots
PLOTSDIR ?= plots


# overall disk size?
DISK_SIZE ?= 8388608

# size to test for litmus testing?
P26_LITMUS_SIZE ?= 32768
# chunks size, i.e. size of writes/reads, for litmus testing?
P26_LITMUS_CHUNK ?= 32
# step size for litmus testing?
P26_LITMUS_STEP ?= 1
# how many samples to measure for litmus testing?
P26_LITMUS_SAMPLES ?= 16

# range of sizes to test for throughput testing?
P26_T_SIZES ?= 1024,2048,4096,8192,16384,32768
# default size for throughput testing?
P26_T_SIZE ?= $(lastword $(subst $(,), ,$(P26_T_SIZES)))
# chunks size, i.e. size of writes/reads, for throughput testing?
P26_T_CHUNK ?= 32
# simulated time, in nanoseconds, for throughput testing?
P26_T_SIMTIME ?= 60000000000 # 1 minute

# range of erase sizes to test for throughput testing
P26_T_BLOCK_SIZES ?= 1024,2048,4096,8192,16384,32768,65536,131072
# range of read/prog sizes to test for throughput testing
P26_T_PAGE_SIZES ?= 1,4,8,16,32,64,128,256,512
# range of cache sizes to test for throughput testing
P26_T_CACHE_SIZES ?= 8,32,128,512,2048,8192,32768,131072


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
NAND_READ_TIME  ?= 31     # tRD1=25 us, p=2048, s=512 (25 us / 2048 + bus)
NAND_PROG_TIME  ?= 141    # tPP=250 us, p=2048, s=512 (250 us / 2048 + bus)
NAND_ERASE_TIME ?= 15     # tBE=2 ms, block=131072 (2 ms / 131072)



# find source files

# littlefs v3 sources
CODEMAP_LFS3_SRC ?= $(filter-out %.t.c %.b.c %.a.c,$(wildcard littlefs3/*.c))
CODEMAP_LFS3_OBJ := $(CODEMAP_LFS3_SRC:%.c=$(BUILDDIR)/thumb/%.o)
CODEMAP_LFS3_DEP := $(CODEMAP_LFS3_SRC:%.c=$(BUILDDIR)/thumb/%.d)
CODEMAP_LFS3_ASM := $(CODEMAP_LFS3_SRC:%.c=$(BUILDDIR)/thumb/%.s)
CODEMAP_LFS3_CI  := $(CODEMAP_LFS3_SRC:%.c=$(BUILDDIR)/thumb/%.ci)

# littlefs v2 sources
CODEMAP_LFS2_SRC ?= $(filter-out %.t.c %.b.c %.a.c,$(wildcard littlefs2/*.c))
CODEMAP_LFS2_OBJ := $(CODEMAP_LFS2_SRC:%.c=$(BUILDDIR)/thumb/%.o)
CODEMAP_LFS2_DEP := $(CODEMAP_LFS2_SRC:%.c=$(BUILDDIR)/thumb/%.d)
CODEMAP_LFS2_ASM := $(CODEMAP_LFS2_SRC:%.c=$(BUILDDIR)/thumb/%.s)
CODEMAP_LFS2_CI  := $(CODEMAP_LFS2_SRC:%.c=$(BUILDDIR)/thumb/%.ci)

# littlefs v1 sources
CODEMAP_LFS1_SRC ?= $(filter-out %.t.c %.b.c %.a.c,$(wildcard littlefs1/*.c))
CODEMAP_LFS1_OBJ := $(CODEMAP_LFS1_SRC:%.c=$(BUILDDIR)/thumb/%.o)
CODEMAP_LFS1_DEP := $(CODEMAP_LFS1_SRC:%.c=$(BUILDDIR)/thumb/%.d)
CODEMAP_LFS1_ASM := $(CODEMAP_LFS1_SRC:%.c=$(BUILDDIR)/thumb/%.s)
CODEMAP_LFS1_CI  := $(CODEMAP_LFS1_SRC:%.c=$(BUILDDIR)/thumb/%.ci)

# littlefs v3 bench-runner (the default)
BENCHES_LFS3 ?= $(wildcard benches/*.toml)
BENCH_LFS3_RUNNER ?= $(BUILDDIR)/bench_lfs3_runner
BENCH_LFS3_SRC ?= \
		$(filter-out %.t.c %.b.c %.a.c,$(wildcard littlefs3/*.c)) \
		$(filter-out %.t.c %.b.c %.a.c,$(wildcard bd/*.c)) \
		runners/bench_runner.c
BENCH_LFS3_C     := \
		$(BENCHES_LFS3:%.toml=$(BUILDDIR)/%.lfs3.b.c) \
		$(BENCH_LFS3_SRC:%.c=$(BUILDDIR)/%.lfs3.b.c)
BENCH_LFS3_A     := $(BENCH_LFS3_C:%.lfs3.b.c=%.lfs3.b.a.c)
BENCH_LFS3_OBJ   := $(BENCH_LFS3_A:%.lfs3.b.a.c=%.lfs3.b.a.o)
BENCH_LFS3_DEP   := $(BENCH_LFS3_A:%.lfs3.b.a.c=%.lfs3.b.a.d)
BENCH_LFS3_CI    := $(BENCH_LFS3_A:%.lfs3.b.a.c=%.lfs3.b.a.ci)
BENCH_LFS3_GCNO  := $(BENCH_LFS3_A:%.lfs3.b.a.c=%.lfs3.b.a.gcno) \
BENCH_LFS3_GCDA  := $(BENCH_LFS3_A:%.lfs3.b.a.c=%.lfs3.b.a.gcda) \
BENCH_LFS3_PERF  := $(BENCH_LFS3_RUNNER:%=%.perf)
BENCH_LFS3_TRACE := $(BENCH_LFS3_RUNNER:%=%.trace)
BENCH_LFS3_CSV   := $(BENCH_LFS3_RUNNER:%=%.csv)

# littlefs v3 no-bmap bench-runner
BENCH_LFS3NB_RUNNER ?= $(BUILDDIR)/bench_lfs3nb_runner
BENCH_LFS3NB_OBJ   := $(BENCH_LFS3_A:%.lfs3.b.a.c=%.lfs3nb.b.a.o)
BENCH_LFS3NB_DEP   := $(BENCH_LFS3_A:%.lfs3.b.a.c=%.lfs3nb.b.a.d)
BENCH_LFS3NB_CI    := $(BENCH_LFS3_A:%.lfs3.b.a.c=%.lfs3nb.b.a.ci)
BENCH_LFS3NB_GCNO  := $(BENCH_LFS3_A:%.lfs3.b.a.c=%.lfs3nb.b.a.gcno) \
BENCH_LFS3NB_GCDA  := $(BENCH_LFS3_A:%.lfs3.b.a.c=%.lfs3nb.b.a.gcda) \
BENCH_LFS3NB_PERF  := $(BENCH_LFS3NB_RUNNER:%=%.perf)
BENCH_LFS3NB_TRACE := $(BENCH_LFS3NB_RUNNER:%=%.trace)
BENCH_LFS3NB_CSV   := $(BENCH_LFS3NB_RUNNER:%=%.csv)

# littlefs v2 bench-runner
BENCHES_LFS2 ?= $(wildcard benches/*.toml)
BENCH_LFS2_RUNNER ?= $(BUILDDIR)/bench_lfs2_runner
BENCH_LFS2_SRC ?= \
		$(filter-out %.t.c %.b.c %.a.c,$(wildcard littlefs2/*.c)) \
		$(filter-out %.t.c %.b.c %.a.c,$(wildcard bd/*.c)) \
		runners/bench_runner.c
BENCH_LFS2_C     := \
		$(BENCHES_LFS2:%.toml=$(BUILDDIR)/%.lfs2.b.c) \
		$(BENCH_LFS2_SRC:%.c=$(BUILDDIR)/%.lfs2.b.c)
BENCH_LFS2_A     := $(BENCH_LFS2_C:%.lfs2.b.c=%.lfs2.b.a.c)
BENCH_LFS2_OBJ   := $(BENCH_LFS2_A:%.lfs2.b.a.c=%.lfs2.b.a.o)
BENCH_LFS2_DEP   := $(BENCH_LFS2_A:%.lfs2.b.a.c=%.lfs2.b.a.d)
BENCH_LFS2_CI    := $(BENCH_LFS2_A:%.lfs2.b.a.c=%.lfs2.b.a.ci)
BENCH_LFS2_GCNO  := $(BENCH_LFS2_A:%.lfs2.b.a.c=%.lfs2.b.a.gcno) \
BENCH_LFS2_GCDA  := $(BENCH_LFS2_A:%.lfs2.b.a.c=%.lfs2.b.a.gcda) \
BENCH_LFS2_PERF  := $(BENCH_LFS2_RUNNER:%=%.perf)
BENCH_LFS2_TRACE := $(BENCH_LFS2_RUNNER:%=%.trace)
BENCH_LFS2_CSV   := $(BENCH_LFS2_RUNNER:%=%.csv)

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
CFLAGS += -std=c99 -Wall -Wextra -pedantic
# labels are useful for debugging, in-function organization, etc
CFLAGS += -Wno-unused-label
CFLAGS += -Wno-unused-function
CFLAGS += -Wno-format-overflow
# compiler bug: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=101854
CFLAGS += -Wno-stringop-overflow
CFLAGS += -ftrack-macro-expansion=0
ifdef DEBUG
CFLAGS += -O0
else
CFLAGS += -Os
endif
ifdef TRACE
CFLAGS += $(foreach P,LFS LFS1 LFS2 LFS3,-D$P_YES_TRACE)
endif
ifdef COVGEN
CFLAGS += --coverage
endif
ifdef PERFGEN
CFLAGS += -fno-omit-frame-pointer
endif
ifdef PERFBDGEN
CFLAGS += -fno-omit-frame-pointer
endif

# also forward all LFS_*, LFS2_*, and LFS3*_ environment variables
CFLAGS += $(foreach D,$(filter LFS_%,$(.VARIABLES)),-D$D=$($D))
CFLAGS += $(foreach D,$(filter LFS1_%,$(.VARIABLES)),-D$D=$($D))
CFLAGS += $(foreach D,$(filter LFS2_%,$(.VARIABLES)),-D$D=$($D))
CFLAGS += $(foreach D,$(filter LFS3_%,$(.VARIABLES)),-D$D=$($D))

# cross-compile codemap, we don't really care about x86 code size
CODEMAP_CC ?= arm-linux-gnueabi-gcc -mthumb --static -Wno-stringop-overflow
CODEMAP_CFLAGS += $(foreach P,LFS LFS1 LFS2 LFS3,-D$P_NO_LOG)
CODEMAP_CFLAGS += $(foreach P,LFS LFS1 LFS2 LFS3,-D$P_NO_DEBUG)
CODEMAP_CFLAGS += $(foreach P,LFS LFS1 LFS2 LFS3,-D$P_NO_INFO)
CODEMAP_CFLAGS += $(foreach P,LFS LFS1 LFS2 LFS3,-D$P_NO_WARN)
CODEMAP_CFLAGS += $(foreach P,LFS LFS1 LFS2 LFS3,-D$P_NO_ERROR)
CODEMAP_CFLAGS += $(foreach P,LFS LFS1 LFS2 LFS3,-D$P_NO_ASSERT)

# bench.py -c flags
ifdef VERBOSE
BENCHCFLAGS += -v
endif

# this is a bit of a hack, but we want to make sure the BUILDDIR
# directory structure is correct before we run any commands
ifneq ($(BUILDDIR),.)
$(if $(findstring n,$(MAKEFLAGS)),, $(shell mkdir -p \
	$(BUILDDIR) \
	$(BUILDDIR)/thumb \
	$(RESULTSDIR) \
	$(CODEMAPSDIR) \
	$(PLOTSDIR) \
    $(addprefix $(BUILDDIR)/,$(dir \
		$(CODEMAP_LFS3_SRC) \
		$(CODEMAP_LFS2_SRC) \
		$(CODEMAP_LFS1_SRC) \
        $(BENCHES_LFS3) \
        $(BENCH_LFS3_SRC) \
        $(BENCH_LFS2_SRC))) \
    $(addprefix $(BUILDDIR)/thumb/,$(dir \
		$(CODEMAP_LFS3_SRC) \
		$(CODEMAP_LFS2_SRC) \
		$(CODEMAP_LFS1_SRC) \
        $(BENCHES_LFS3) \
        $(BENCH_LFS3_SRC) \
        $(BENCH_LFS2_SRC)))))
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
		$(BENCH_LFS3_RUNNER) \
		$(BENCH_LFS3NB_RUNNER) \
		$(BENCH_LFS2_RUNNER)
ifdef COVGEN
	rm -f $(BENCH_LFS3_GCDA)
	rm -f $(BENCH_LFS3NB_GCDA)
	rm -f $(BENCH_LFS2_GCDA)
endif
ifdef PERFGEN
	rm -f $(BENCH_LFS3_PERF)
	rm -f $(BENCH_LFS3NB_PERF)
	rm -f $(BENCH_LFS2_PERF)
endif
ifdef PERFBDGEN
	rm -f $(BENCH_LFS3_TRACE)
	rm -f $(BENCH_LFS3NB_TRACE)
	rm -f $(BENCH_LFS2_TRACE)
endif

## Find total section sizes
.PHONY: size
size: $(BENCH_LFS3_OBJ)
	$(SIZE) -t $^

## Generate a ctags file
.PHONY: tags ctags
tags ctags:
	$(strip $(CTAGS) \
		--totals --fields=+n --c-types=+p \
		$(shell find -H -name '*.h') \
		$(BENCH_LFS3_SRC) \
		$(BENCH_LFS2_SRC))

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


# low-level rules
-include $(BENCH_LFS3_DEP)
-include $(BENCH_LFS2_DEP)
.SUFFIXES:
.SECONDARY:
, := ,

$(BENCH_LFS3_RUNNER): $(BENCH_LFS3_OBJ)
	$(CC) $(CFLAGS) $^ $(LFLAGS) -o$@

$(BENCH_LFS3NB_RUNNER): $(BENCH_LFS3NB_OBJ)
	$(CC) $(CFLAGS) $^ $(LFLAGS) -o$@

$(BENCH_LFS2_RUNNER): $(BENCH_LFS2_OBJ)
	$(CC) $(CFLAGS) $^ $(LFLAGS) -o$@

# our main build rule generates .o, .d, and .ci files, the latter
# used for stack analysis

# cross-compile for codemap
$(BUILDDIR)/thumb/%.o $(BUILDDIR)/thumb/%.ci: %.c
	$(strip $(CODEMAP_CC) -c -MMD $(CFLAGS) $(CODEMAP_CFLAGS) $< \
		-o $(BUILDDIR)/thumb/$*.o)

$(BUILDDIR)/thumb/%.o $(BUILDDIR)/thumb/%.ci: $(BUILDDIR)/thumb/%.c
	$(strip $(CODEMAP_CC) -c -MMD $(CFLAGS) $(CODEMAP_CFLAGS) $< \
		-o $(BUILDDIR)/thumb/$*.o)

# rdonly codemap builds
$(BUILDDIR)/thumb/%.rdonly.o $(BUILDDIR)/thumb/%.rdonly.ci: \
		%.c
	$(strip $(CODEMAP_CC) -c -MMD $(CFLAGS) \
		-DLFS3_RDONLY -DLFS2_READONLY \
		$(CODEMAP_CFLAGS) $< \
		-o $(BUILDDIR)/thumb/$*.rdonly.o)

$(BUILDDIR)/thumb/%.rdonly.o $(BUILDDIR)/thumb/%.rdonly.ci: \
		$(BUILDDIR)/thumb/%.c
	$(strip $(CODEMAP_CC) -c -MMD $(CFLAGS) \
		-DLFS3_RDONLY -DLFS2_READONLY \
		$(CODEMAP_CFLAGS) $< \
		-o $(BUILDDIR)/thumb/$*.rdonly.o)

# .lfs3 files need -DLFS3=1 -DLFS3_YES_BMAP=1
$(BUILDDIR)/%.lfs3.b.a.o $(BUILDDIR)/%.lfs3.b.a.ci: %.lfs3.b.a.c
	$(strip $(CC) -c -MMD -DLFS3=1 -DLFS3_YES_BMAP=1 \
		$(CFLAGS) $< -o $(BUILDDIR)/$*.lfs3.b.a.o)

$(BUILDDIR)/%.lfs3.b.a.o $(BUILDDIR)/%.lfs3.b.a.ci: $(BUILDDIR)/%.lfs3.b.a.c
	$(strip $(CC) -c -MMD -DLFS3=1 -DLFS3_YES_BMAP=1 \
		$(CFLAGS) $< -o $(BUILDDIR)/$*.lfs3.b.a.o)

# .lfs3nb files need -DLFS3=1
$(BUILDDIR)/%.lfs3nb.b.a.o $(BUILDDIR)/%.lfs3nb.b.a.ci: %.lfs3.b.a.c
	$(CC) -c -MMD -DLFS3=1 $(CFLAGS) $< -o $(BUILDDIR)/$*.lfs3nb.b.a.o

$(BUILDDIR)/%.lfs3nb.b.a.o $(BUILDDIR)/%.lfs3nb.b.a.ci: $(BUILDDIR)/%.lfs3.b.a.c
	$(CC) -c -MMD -DLFS3=1 $(CFLAGS) $< -o $(BUILDDIR)/$*.lfs3nb.b.a.o

# .lfs2 files need -DLFS2=1
$(BUILDDIR)/%.lfs2.b.a.o $(BUILDDIR)/%.lfs2.b.a.ci: %.lfs2.b.a.c
	$(CC) -c -MMD -DLFS2=1 $(CFLAGS) $< -o $(BUILDDIR)/$*.lfs2.b.a.o

$(BUILDDIR)/%.lfs2.b.a.o $(BUILDDIR)/%.lfs2.b.a.ci: $(BUILDDIR)/%.lfs2.b.a.c
	$(CC) -c -MMD -DLFS2=1 $(CFLAGS) $< -o $(BUILDDIR)/$*.lfs2.b.a.o

$(BUILDDIR)/%.s: %.c
	$(CC) -S $(CFLAGS) $< -o$@

$(BUILDDIR)/%.s: $(BUILDDIR)/%.c
	$(CC) -S $(CFLAGS) $< -o$@

$(BUILDDIR)/%.a.c: %.c
	$(PRETTYASSERTS) -Plfs_ -Plfs1_ -Plfs2_ -Plfs3_ $< -o$@

$(BUILDDIR)/%.a.c: $(BUILDDIR)/%.c
	$(PRETTYASSERTS) -Plfs_ -Plfs1_ -Plfs2_ -Plfs3_ $< -o$@

# limit .lfs3 files to lfs3 benches
$(BUILDDIR)/%.lfs3.b.c: %.toml
	./scripts/bench.py -c $< $(BENCHCFLAGS) -o$@

$(BUILDDIR)/%.lfs3.b.c: %.c $(BENCHES_LFS3)
	./scripts/bench.py -c $(BENCHES_LFS3) -s $< $(BENCHCFLAGS) -o$@

# limit .lfs2 files to lfs2 benches
$(BUILDDIR)/%.lfs2.b.c: %.toml
	./scripts/bench.py -c $< $(BENCHCFLAGS) -o$@

$(BUILDDIR)/%.lfs2.b.c: %.c $(BENCHES_LFS2)
	./scripts/bench.py -c $(BENCHES_LFS2) -s $< $(BENCHCFLAGS) -o$@



#======================================================================#
# ok! with that out of the way, here's our actual benchmark rules      #
#======================================================================#

# bench.py flags
# give us a big disk
BENCHFLAGS += -DDISK_SIZE=$(DISK_SIZE)
BENCHFLAGS += -b
# just always run benches in parallel, this makefile uses too much RAM
# to parallelize at the rule level
BENCHFLAGS += -j
# # forward -j flag
# BENCHFLAGS += $(filter -j%,$(MAKEFLAGS))
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


## Run all benchmarks!
.PHONY: bench bench-all
bench bench-all: \
		bench-p26

## Run p26 benchmarks
.PHONY: bench-p26
bench-p26: \
		bench-p26-litmus \
		bench-p26-wt \
		bench-p26-rt \
		bench-p26-wt-bs \
		bench-p26-wt-ps \
		bench-p26-wt-cs

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
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_litmus_linear.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_litmus_linear.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_litmus_linear.lfs2.$(SIM).csv)

## Run p26 litmus random benchmarks
.PHONY: bench-p26-litmus-random
bench-p26-litmus-random: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_litmus_random.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_litmus_random.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_litmus_random.lfs2.$(SIM).csv)

## Run p26 litmus many benchmarks
.PHONY: bench-p26-litmus-many
bench-p26-litmus-many: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_litmus_many.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_litmus_many.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_litmus_many.lfs2.$(SIM).csv)

## Run p26 litmus logging benchmarks
.PHONY: bench-p26-litmus-logging
bench-p26-litmus-logging: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_litmus_logging.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_litmus_logging.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_litmus_logging.lfs2.$(SIM).csv)

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
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_wt_linear.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_linear.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_linear.lfs2.$(SIM).csv)

## Run p26 write-throughput random benchmarks
.PHONY: bench-p26-wt-random
bench-p26-wt-random: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_wt_random.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_random.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_random.lfs2.$(SIM).csv)

## Run p26 write-throughput many benchmarks
.PHONY: bench-p26-wt-many
bench-p26-wt-many: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_wt_many.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_many.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_many.lfs2.$(SIM).csv)

## Run p26 write-throughput logging benchmarks
.PHONY: bench-p26-wt-logging
bench-p26-wt-logging: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_wt_logging.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_logging.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_logging.lfs2.$(SIM).csv)

## Run p26 read-throughput benchmarks
.PHONY: bench-p26-rt
bench-p26-rt: \
		bench-p26-rt-linear \
		bench-p26-rt-random \
		bench-p26-rt-many

## Run p26 read-throughput linear benchmarks
.PHONY: bench-p26-rt-linear
bench-p26-rt-linear: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_rt_linear.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_rt_linear.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_rt_linear.lfs2.$(SIM).csv)

## Run p26 read-throughput random benchmarks
.PHONY: bench-p26-rt-random
bench-p26-rt-random: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_rt_random.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_rt_random.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_rt_random.lfs2.$(SIM).csv)

## Run p26 read-throughput many benchmarks
.PHONY: bench-p26-rt-many
bench-p26-rt-many: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_rt_many.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_rt_many.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_rt_many.lfs2.$(SIM).csv)

## Run p26 write-throughput block size benchmarks
.PHONY: bench-p26-wt-bs
bench-p26-wt-bs: \
		bench-p26-wt-bs-linear \
		bench-p26-wt-bs-random \
		bench-p26-wt-bs-many \
		bench-p26-wt-bs-logging

## Run p26 write-throughput block size linear benchmarks
.PHONY: bench-p26-wt-bs-linear
bench-p26-wt-bs-linear: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_wt_bs_linear.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_bs_linear.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_bs_linear.lfs2.$(SIM).csv)

## Run p26 write-throughput block size random benchmarks
.PHONY: bench-p26-wt-bs-random
bench-p26-wt-bs-random: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_wt_bs_random.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_bs_random.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_bs_random.lfs2.$(SIM).csv)

## Run p26 write-throughput block size many benchmarks
.PHONY: bench-p26-wt-bs-many
bench-p26-wt-bs-many: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_wt_bs_many.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_bs_many.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_bs_many.lfs2.$(SIM).csv)

## Run p26 write-throughput block size logging benchmarks
.PHONY: bench-p26-wt-bs-logging
bench-p26-wt-bs-logging: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_wt_bs_logging.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_bs_logging.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_bs_logging.lfs2.$(SIM).csv)

## Run p26 write-throughput read/prog size benchmarks
.PHONY: bench-p26-wt-ps
bench-p26-wt-ps: \
		bench-p26-wt-ps-linear \
		bench-p26-wt-ps-random \
		bench-p26-wt-ps-many \
		bench-p26-wt-ps-logging

## Run p26 write-throughput read/prog size linear benchmarks
.PHONY: bench-p26-wt-ps-linear
bench-p26-wt-ps-linear: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_wt_ps_linear.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_ps_linear.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_ps_linear.lfs2.$(SIM).csv)

## Run p26 write-throughput read/prog size random benchmarks
.PHONY: bench-p26-wt-ps-random
bench-p26-wt-ps-random: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_wt_ps_random.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_ps_random.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_ps_random.lfs2.$(SIM).csv)

## Run p26 write-throughput read/prog size many benchmarks
.PHONY: bench-p26-wt-ps-many
bench-p26-wt-ps-many: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_wt_ps_many.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_ps_many.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_ps_many.lfs2.$(SIM).csv)

## Run p26 write-throughput read/prog size logging benchmarks
.PHONY: bench-p26-wt-ps-logging
bench-p26-wt-ps-logging: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_wt_ps_logging.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_ps_logging.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_ps_logging.lfs2.$(SIM).csv)

## Run p26 write-throughput cache size benchmarks
.PHONY: bench-p26-wt-cs
bench-p26-wt-cs: \
		bench-p26-wt-cs-linear \
		bench-p26-wt-cs-random \
		bench-p26-wt-cs-many \
		bench-p26-wt-cs-logging

## Run p26 write-throughput cache size linear benchmarks
.PHONY: bench-p26-wt-cs-linear
bench-p26-wt-cs-linear: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_wt_cs_linear.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_cs_linear.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_cs_linear.lfs2.$(SIM).csv)

## Run p26 write-throughput cache size random benchmarks
.PHONY: bench-p26-wt-cs-random
bench-p26-wt-cs-random: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_wt_cs_random.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_cs_random.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_cs_random.lfs2.$(SIM).csv)

## Run p26 write-throughput cache size many benchmarks
.PHONY: bench-p26-wt-cs-many
bench-p26-wt-cs-many: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_wt_cs_many.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_cs_many.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_cs_many.lfs2.$(SIM).csv)

## Run p26 write-throughput cache size logging benchmarks
.PHONY: bench-p26-wt-cs-logging
bench-p26-wt-cs-logging: \
		$(foreach SIM, emmc nor nand, \
			$(RESULTSDIR)/bench_p26_wt_cs_logging.lfs3.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_cs_logging.lfs3nb.$(SIM).csv \
			$(RESULTSDIR)/bench_p26_wt_cs_logging.lfs2.$(SIM).csv)


# some lfs3 -> LFS3 convenience mappings
UFS = $(if $(filter lfs3,$1),LFS3,$\
		$(if $(filter lfs3nb,$1),LFS3NB,$\
		$(if $(filter lfs2,$1),LFS2)))

USIM = $(if $(filter emmc,$1),EMMC,$\
		$(if $(filter nor,$1),NOR,$\
		$(if $(filter nand,$1),NAND)))

# p26 bench rules!

# p26 litmus bench rule
#
# $1 - target
# $2 - bench case
# $3 - fs type/version
# $4 - sim type
#
define BENCH_P26_LITMUS_RULE
$1: $$(BENCH_$(call UFS,$3)_RUNNER)
	$$(strip ./scripts/bench.py -R$$< -B $2 \
		-DSIZE=$(P26_LITMUS_SIZE) \
		-DCHUNK=$(P26_LITMUS_CHUNK) \
		-DSTEP=$(P26_LITMUS_STEP) \
		-DSEED="range($(P26_LITMUS_SAMPLES))" \
		-DFS=$(if $(filter lfs3,$3),3,$\
			$(if $(filter lfs3nb,$3),30,$\
			$(if $(filter lfs2,$3),2))) \
		-DREAD_SIZE=$$($(call USIM,$4)_READ_SIZE) \
		-DPROG_SIZE=$$($(call USIM,$4)_PROG_SIZE) \
		-DERASE_SIZE=$$($(call USIM,$4)_ERASE_SIZE) \
		-DREAD_TIME=$$($(call USIM,$4)_READ_TIME) \
		-DPROG_TIME=$$($(call USIM,$4)_PROG_TIME) \
		-DERASE_TIME=$$($(call USIM,$4)_ERASE_TIME) \
		-DBLOCK_SIZE=$$($(call USIM,$4)_$(call UFS,$3)_BLOCK_SIZE) \
		$$(BENCHFLAGS) \
		-o$$@)
endef

$(foreach FS,lfs3 lfs3nb lfs2,$\
	$(foreach SIM,emmc nor nand,$\
		$(eval $(call BENCH_P26_LITMUS_RULE,$\
				$(RESULTSDIR)/bench_p26_litmus_%.$(FS).$(SIM).csv,$\
				bench_p26_litmus_$$*,$\
				$(FS),$\
				$(SIM)))))


# p26 read/write-throughput bench rule
#
# $1 - target
# $2 - bench case
# $3 - fs type/version
# $4 - sim type
#
define BENCH_P26_T_RULE
$1: $$(BENCH_$(call UFS,$3)_RUNNER)
	$$(strip ./scripts/bench.py -R$$< -B $2 \
		-DSIZE=$(P26_T_SIZES) \
		-DCHUNK=$(P26_T_CHUNK) \
		-DSIMTIME=$(P26_T_SIMTIME) \
		-DFS=$(if $(filter lfs3,$3),3,$\
			$(if $(filter lfs3nb,$3),30,$\
			$(if $(filter lfs2,$3),2))) \
		-DREAD_SIZE=$$($(call USIM,$4)_READ_SIZE) \
		-DPROG_SIZE=$$($(call USIM,$4)_PROG_SIZE) \
		-DERASE_SIZE=$$($(call USIM,$4)_ERASE_SIZE) \
		-DREAD_TIME=$$($(call USIM,$4)_READ_TIME) \
		-DPROG_TIME=$$($(call USIM,$4)_PROG_TIME) \
		-DERASE_TIME=$$($(call USIM,$4)_ERASE_TIME) \
		-DBLOCK_SIZE=$$($(call USIM,$4)_$(call UFS,$3)_BLOCK_SIZE) \
		$$(BENCHFLAGS) \
		-o$$@)
endef

# p26 write-throughput bench rules
$(foreach FS,lfs3 lfs3nb lfs2,$\
	$(foreach SIM,emmc nor nand,$\
		$(eval $(call BENCH_P26_T_RULE,$\
				$(RESULTSDIR)/bench_p26_wt_%.$(FS).$(SIM).csv,$\
				bench_p26_wt_$$*,$\
				$(FS),$\
				$(SIM)))))

# p26 read-throughput bench rules
$(foreach FS,lfs3 lfs3nb lfs2,$\
	$(foreach SIM,emmc nor nand,$\
		$(eval $(call BENCH_P26_T_RULE,$\
				$(RESULTSDIR)/bench_p26_rt_%.$(FS).$(SIM).csv,$\
				bench_p26_rt_$$*,$\
				$(FS),$\
				$(SIM)))))

# p26 read/write-throughput block size bench rule
#
# $1 - target
# $2 - bench case
# $3 - fs type/version
# $4 - sim type
#
define BENCH_P26_T_BS_RULE
$1: $$(BENCH_$(call UFS,$3)_RUNNER)
	$$(strip ./scripts/bench.py -R$$< -B $2 \
		-DSIZE=$(P26_T_SIZE) \
		-DCHUNK=$(P26_T_CHUNK) \
		-DSIMTIME=$(P26_T_SIMTIME) \
		-DFS=$(if $(filter lfs3,$3),3,$\
			$(if $(filter lfs3nb,$3),30,$\
			$(if $(filter lfs2,$3),2))) \
		-DREAD_SIZE=$$($(call USIM,$4)_READ_SIZE) \
		-DPROG_SIZE=$$($(call USIM,$4)_PROG_SIZE) \
		-DERASE_SIZE=$$($(call USIM,$4)_ERASE_SIZE) \
		-DREAD_TIME=$$($(call USIM,$4)_READ_TIME) \
		-DPROG_TIME=$$($(call USIM,$4)_PROG_TIME) \
		-DERASE_TIME=$$($(call USIM,$4)_ERASE_TIME) \
		-DBLOCK_SIZE=$(P26_T_BLOCK_SIZES) \
		$$(BENCHFLAGS) \
		-o$$@)
endef

# p26 write-throughput block size bench rules
$(foreach FS,lfs3 lfs3nb lfs2,$\
	$(foreach SIM,emmc nor nand,$\
		$(eval $(call BENCH_P26_T_BS_RULE,$\
				$(RESULTSDIR)/bench_p26_wt_bs_%.$(FS).$(SIM).csv,$\
				bench_p26_wt_$$*,$\
				$(FS),$\
				$(SIM)))))

# p26 read/write-throughput read/prog size bench rule
#
# $1 - target
# $2 - bench case
# $3 - fs type/version
# $4 - sim type
#
# note we set CACHE_SIZE = max(PAGE_SIZE) to prevent PAGE_SIZE-dependent
# caches from messing with the results
#
define BENCH_P26_T_PS_RULE
$1: $$(BENCH_$(call UFS,$3)_RUNNER)
	$$(strip ./scripts/bench.py -R$$< -B $2 \
		-DSIZE=$(P26_T_SIZE) \
		-DCHUNK=$(P26_T_CHUNK) \
		-DSIMTIME=$(P26_T_SIMTIME) \
		-DFS=$(if $(filter lfs3,$3),3,$\
			$(if $(filter lfs3nb,$3),30,$\
			$(if $(filter lfs2,$3),2))) \
		-DPAGE_SIZE=$(P26_T_PAGE_SIZES) \
		-DERASE_SIZE=$$($(call USIM,$4)_ERASE_SIZE) \
		-DREAD_TIME=$$($(call USIM,$4)_READ_TIME) \
		-DPROG_TIME=$$($(call USIM,$4)_PROG_TIME) \
		-DERASE_TIME=$$($(call USIM,$4)_ERASE_TIME) \
		-DBLOCK_SIZE=$$($(call USIM,$4)_$(call UFS,$3)_BLOCK_SIZE) \
		-DCACHE_SIZE=$$(shell python -c 'print(max([$(P26_T_PAGE_SIZES)]))') \
		$$(BENCHFLAGS) \
		-o$$@)
endef

# p26 write-throughput read/prog size bench rules
$(foreach FS,lfs3 lfs3nb lfs2,$\
	$(foreach SIM,emmc nor nand,$\
		$(eval $(call BENCH_P26_T_PS_RULE,$\
				$(RESULTSDIR)/bench_p26_wt_ps_%.$(FS).$(SIM).csv,$\
				bench_p26_wt_$$*,$\
				$(FS),$\
				$(SIM)))))

# p26 read/write-throughput cache size bench rule
#
# $1 - target
# $2 - bench case
# $3 - fs type/version
# $4 - sim type
#
define BENCH_P26_T_CS_RULE
$1: $$(BENCH_$(call UFS,$3)_RUNNER)
	$$(strip ./scripts/bench.py -R$$< -B $2 \
		-DSIZE=$(P26_T_SIZE) \
		-DCHUNK=$(P26_T_CHUNK) \
		-DSIMTIME=$(P26_T_SIMTIME) \
		-DFS=$(if $(filter lfs3,$3),3,$\
			$(if $(filter lfs3nb,$3),30,$\
			$(if $(filter lfs2,$3),2))) \
		-DREAD_SIZE=$$($(call USIM,$4)_READ_SIZE) \
		-DPROG_SIZE=$$($(call USIM,$4)_PROG_SIZE) \
		-DERASE_SIZE=$$($(call USIM,$4)_ERASE_SIZE) \
		-DREAD_TIME=$$($(call USIM,$4)_READ_TIME) \
		-DPROG_TIME=$$($(call USIM,$4)_PROG_TIME) \
		-DERASE_TIME=$$($(call USIM,$4)_ERASE_TIME) \
		-DBLOCK_SIZE=$$($(call USIM,$4)_$(call UFS,$3)_BLOCK_SIZE) \
		-DCACHE_SIZE=$$(shell python -c '$\
			print(",".join(str(n) for n in [$(P26_T_CACHE_SIZES)] $\
				if n >= $$($(call USIM,$4)_READ_SIZE) $\
				and n >= $$($(call USIM,$4)_PROG_SIZE) $\
				and n <= $$($(call USIM,$4)_$(call UFS,$3)_BLOCK_SIZE) $\
				and ("$$*" not in {"linear", "random"} $\
					or n < $(P26_T_SIZE))))') \
		$$(BENCHFLAGS) \
		-o$$@)
endef

# p26 write-throughput cache size bench rules
$(foreach FS,lfs3 lfs3nb lfs2,$\
	$(foreach SIM,emmc nor nand,$\
		$(eval $(call BENCH_P26_T_CS_RULE,$\
				$(RESULTSDIR)/bench_p26_wt_cs_%.$(FS).$(SIM).csv,$\
				bench_p26_wt_$$*,$\
				$(FS),$\
				$(SIM)))))


# simulated/estimated results
$(RESULTSDIR)/bench_%.sim.csv: $(RESULTSDIR)/bench_%.csv
	$(strip ./scripts/csv.py $^ \
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
	$(strip ./scripts/csv.py \
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

# amortized results
$(RESULTSDIR)/bench_%.amor.csv: $(RESULTSDIR)/bench_%.csv
	$(strip ./scripts/csv.py $^ \
		-Bn -Bm='%(m)s+amor' \
		-fbench_readed='float(bench_creaded) / float(n)' \
		-fbench_proged='float(bench_cproged) / float(n)' \
		-fbench_erased='float(bench_cerased) / float(n)' \
		-o$@)

# per-byte/entry usage results
$(RESULTSDIR)/bench_%.per.csv: $(RESULTSDIR)/bench_%.csv
	$(strip ./scripts/csv.py $^ \
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
	$(strip ./scripts/csv.py $^ \
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
# and codemap rules                                                    #
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



## Generate all codemaps!
.PHONY: codemap
codemap codemap-all: \
		codemap-default
# TODO
#		codemap-rdonly

## Generate codemaps for the default build
.PHONY: codemap-default
codemap-default: \
		$(CODEMAPSDIR)/codemap_lfs3_tiny.svg \
		$(CODEMAPSDIR)/codemap_lfs2_tiny.svg \
		$(CODEMAPSDIR)/codemap_lfs1_tiny.svg \
		$(CODEMAPSDIR)/codemap_lfs3.svg \
		$(CODEMAPSDIR)/codemap_lfs2.svg \
		$(CODEMAPSDIR)/codemap_lfs1.svg

### Generate codemaps for the rdonly build
#.PHONY: codemap-rdonly
#codemap-rdonly: \
#		$(CODEMAPSDIR)/codemap_lfs3_rdonly_tiny.svg \
#		$(CODEMAPSDIR)/codemap_lfs2_rdonly_tiny.svg \
#		$(CODEMAPSDIR)/codemap_lfs3_rdonly.svg \
#		$(CODEMAPSDIR)/codemap_lfs2_rdonly.svg


# codemap rules!

# normal codemap rule
#
# $1 - target
# $2 - sources
# $3 - version
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

$(eval $(call CODEMAP_RULE,$\
		$(CODEMAPSDIR)/codemap_lfs3.svg,$\
		$(CODEMAP_LFS3_OBJ) $(CODEMAP_LFS3_CI),$\
		lfs3))
$(eval $(call CODEMAP_RULE,$\
		$(CODEMAPSDIR)/codemap_lfs2.svg,$\
		$(CODEMAP_LFS2_OBJ) $(CODEMAP_LFS2_CI),$\
		lfs2))
$(eval $(call CODEMAP_RULE,$\
		$(CODEMAPSDIR)/codemap_lfs1.svg,$\
		$(CODEMAP_LFS1_OBJ) $(CODEMAP_LFS1_CI),$\
		lfs1))

$(eval $(call CODEMAP_RULE,$\
		$(CODEMAPSDIR)/codemap_lfs3_rdonly.svg,$\
		$(CODEMAP_LFS3_OBJ:.o=.rdonly.o) $(CODEMAP_LFS3_CI:.ci=.rdonly.ci),$\
		lfs3))
$(eval $(call CODEMAP_RULE,$\
		$(CODEMAPSDIR)/codemap_lfs2_rdonly.svg,$\
		$(CODEMAP_LFS2_OBJ:.o=.rdonly.o) $(CODEMAP_LFS2_CI:.ci=.rdonly.ci),$\
		lfs2))
$(eval $(call CODEMAP_RULE,$\
		$(CODEMAPSDIR)/codemap_lfs1_rdonly.svg,$\
		$(CODEMAP_LFS1_OBJ:.o=.rdonly.o) $(CODEMAP_LFS1_CI:.ci=.rdonly.ci),$\
		lfs1))

# tiny codemap rule
#
# $1 - target
# $2 - sources
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

$(eval $(call CODEMAP_TINY_RULE,$\
		$(CODEMAPSDIR)/codemap_lfs3_tiny.svg,$\
		$(CODEMAP_LFS3_OBJ) $(CODEMAP_LFS3_CI)))
$(eval $(call CODEMAP_TINY_RULE,$\
		$(CODEMAPSDIR)/codemap_lfs2_tiny.svg,$\
		$(CODEMAP_LFS2_OBJ) $(CODEMAP_LFS2_CI)))
$(eval $(call CODEMAP_TINY_RULE,$\
		$(CODEMAPSDIR)/codemap_lfs1_tiny.svg,$\
		$(CODEMAP_LFS1_OBJ) $(CODEMAP_LFS1_CI)))

$(eval $(call CODEMAP_TINY_RULE,$\
		$(CODEMAPSDIR)/codemap_lfs3_rdonly_tiny.svg,$\
		$(CODEMAP_LFS3_OBJ:.o=.rdonly.o) $(CODEMAP_LFS3_CI:.ci=.rdonly.ci)))
$(eval $(call CODEMAP_TINY_RULE,$\
		$(CODEMAPSDIR)/codemap_lfs2_rdonly_tiny.svg,$\
		$(CODEMAP_LFS2_OBJ:.o=.rdonly.o) $(CODEMAP_LFS2_CI:.ci=.rdonly.ci)))
$(eval $(call CODEMAP_TINY_RULE,$\
		$(CODEMAPSDIR)/codemap_lfs1_rdonly_tiny.svg,$\
		$(CODEMAP_LFS1_OBJ:.o=.rdonly.o) $(CODEMAP_LFS1_CI:.ci=.rdonly.ci)))



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

ifdef LIGHT
PLOT_COLORS ?= \
		\#4c72b0bf $(if, blue    ) \
		\#dd8452bf $(if, orange  ) \
		\#55a868bf $(if, green   ) \
		\#c44e52bf $(if, red     ) \
		\#8172b3bf $(if, purple  ) \
		\#937860bf $(if, brown   ) \
		\#da8bc3bf $(if, pink    ) \
		\#8c8c8cbf $(if, gray    ) \
		\#ccb974bf $(if, yellow  ) \
		\#64b5cdbf $(if, cyan    )
else
PLOT_COLORS ?= \
		\#a1c9f4bf $(if, blue    ) \
		\#ffb482bf $(if, orange  ) \
		\#8de5a1bf $(if, green   ) \
		\#ff9f9bbf $(if, red     ) \
		\#d0bbffbf $(if, purple  ) \
		\#debb9bbf $(if, brown   ) \
		\#fab0e4bf $(if, pink    ) \
		\#cfcfcfbf $(if, gray    ) \
		\#fffea3bf $(if, yellow  ) \
		\#b9f2f0bf $(if, cyan    )
endif
PLOT_COLORS_1 := $(foreach C, $(PLOT_COLORS), \
		-C$C)
PLOT_COLORS_2 := $(foreach C, $(PLOT_COLORS), \
		-C$C \
		-C$C)
PLOT_COLORS_3 := $(foreach C, $(PLOT_COLORS), \
		-C$C \
		-C$C \
		-C$C)
PLOT_COLORS_1BND := $(foreach C, $(PLOT_COLORS), \
		-C$C -C$(C:bf=1f))
PLOT_COLORS_2BND := $(foreach C, $(PLOT_COLORS), \
		-C$C -C$(C:bf=1f) \
		-C$C -C$(C:bf=1f))
PLOT_COLORS_3BND := $(foreach C, $(PLOT_COLORS), \
		-C$C -C$(C:bf=1f) \
		-C$C -C$(C:bf=1f) \
		-C$C -C$(C:bf=1f))



## Plot all benchmarks!
.PHONY: plot plot-all
plot plot-all: \
		plot-p26

## Plot p26 benchmarks
.PHONY: plot-p26
plot-p26: \
		plot-p26-litmus \
		plot-p26-wt \
		plot-p26-rt \
		plot-p26-wt-bs \
		plot-p26-wt-ps \
		plot-p26-wt-cs

## Plot p26 litmus benchmarks
.PHONY: plot-p26-litmus
plot-p26-litmus: \
		plot-p26-litmus-linear \
		plot-p26-litmus-random \
		plot-p26-litmus-many \
		plot-p26-litmus-logging

## Plot p26 litmus linear benchmarks
.PHONY: plot-p26-litmus-linear
plot-p26-litmus-linear: \
		$(PLOTSDIR)/bench_p26_litmus_linear_r.svg \
		$(PLOTSDIR)/bench_p26_litmus_linear_p.svg \
		$(PLOTSDIR)/bench_p26_litmus_linear_e.svg \
		$(PLOTSDIR)/bench_p26_litmus_linear_u.svg \
		$(PLOTSDIR)/bench_p26_litmus_linear.svg

## Plot p26 litmus random benchmarks
.PHONY: plot-p26-litmus-random
plot-p26-litmus-random: \
		$(PLOTSDIR)/bench_p26_litmus_random_r.svg \
		$(PLOTSDIR)/bench_p26_litmus_random_p.svg \
		$(PLOTSDIR)/bench_p26_litmus_random_e.svg \
		$(PLOTSDIR)/bench_p26_litmus_random_u.svg \
		$(PLOTSDIR)/bench_p26_litmus_random.svg

## Plot p26 litmus many benchmarks
.PHONY: plot-p26-litmus-many
plot-p26-litmus-many: \
		$(PLOTSDIR)/bench_p26_litmus_many_r.svg \
		$(PLOTSDIR)/bench_p26_litmus_many_p.svg \
		$(PLOTSDIR)/bench_p26_litmus_many_e.svg \
		$(PLOTSDIR)/bench_p26_litmus_many_u.svg \
		$(PLOTSDIR)/bench_p26_litmus_many.svg

## Plot p26 litmus logging benchmarks
.PHONY: plot-p26-litmus-logging
plot-p26-litmus-logging: \
		$(PLOTSDIR)/bench_p26_litmus_logging_r.svg \
		$(PLOTSDIR)/bench_p26_litmus_logging_p.svg \
		$(PLOTSDIR)/bench_p26_litmus_logging_e.svg \
		$(PLOTSDIR)/bench_p26_litmus_logging_u.svg \
		$(PLOTSDIR)/bench_p26_litmus_logging.svg

## Plot p26 write-throughput benchmarks
.PHONY: plot-p26-wt
plot-p26-wt: \
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

## Plot p26 write-throughput block size benchmarks
.PHONY: plot-p26-wt-bs
plot-p26-wt-bs: \
		plot-p26-wt-bs-linear \
		plot-p26-wt-bs-random \
		plot-p26-wt-bs-many \
		plot-p26-wt-bs-logging

## Plot p26 write-throughput linear block size benchmarks
.PHONY: plot-p26-wt-bs-linear
plot-p26-wt-bs-linear: \
		$(PLOTSDIR)/bench_p26_wt_bs_linear.svg

## Plot p26 write-throughput random block size benchmarks
.PHONY: plot-p26-wt-bs-random
plot-p26-wt-bs-random: \
		$(PLOTSDIR)/bench_p26_wt_bs_random.svg

## Plot p26 write-throughput many block size benchmarks
.PHONY: plot-p26-wt-bs-many
plot-p26-wt-bs-many: \
		$(PLOTSDIR)/bench_p26_wt_bs_many.svg

## Plot p26 write-throughput logging block size benchmarks
.PHONY: plot-p26-wt-bs-logging
plot-p26-wt-bs-logging: \
		$(PLOTSDIR)/bench_p26_wt_bs_logging.svg

## Plot p26 write-throughput read/prog size benchmarks
.PHONY: plot-p26-wt-ps
plot-p26-wt-ps: \
		plot-p26-wt-ps-linear \
		plot-p26-wt-ps-random \
		plot-p26-wt-ps-many \
		plot-p26-wt-ps-logging

## Plot p26 write-throughput linear read/prog size benchmarks
.PHONY: plot-p26-wt-ps-linear
plot-p26-wt-ps-linear: \
		$(PLOTSDIR)/bench_p26_wt_ps_linear.svg

## Plot p26 write-throughput random read/prog size benchmarks
.PHONY: plot-p26-wt-ps-random
plot-p26-wt-ps-random: \
		$(PLOTSDIR)/bench_p26_wt_ps_random.svg

## Plot p26 write-throughput many read/prog size benchmarks
.PHONY: plot-p26-wt-ps-many
plot-p26-wt-ps-many: \
		$(PLOTSDIR)/bench_p26_wt_ps_many.svg

## Plot p26 write-throughput logging read/prog size benchmarks
.PHONY: plot-p26-wt-ps-logging
plot-p26-wt-ps-logging: \
		$(PLOTSDIR)/bench_p26_wt_ps_logging.svg

## Plot p26 write-throughput cache size benchmarks
.PHONY: plot-p26-wt-cs
plot-p26-wt-cs: \
		plot-p26-wt-cs-linear \
		plot-p26-wt-cs-random \
		plot-p26-wt-cs-many \
		plot-p26-wt-cs-logging

## Plot p26 write-throughput linear cache size benchmarks
.PHONY: plot-p26-wt-cs-linear
plot-p26-wt-cs-linear: \
		$(PLOTSDIR)/bench_p26_wt_cs_linear.svg

## Plot p26 write-throughput random cache size benchmarks
.PHONY: plot-p26-wt-cs-random
plot-p26-wt-cs-random: \
		$(PLOTSDIR)/bench_p26_wt_cs_random.svg

## Plot p26 write-throughput many cache size benchmarks
.PHONY: plot-p26-wt-cs-many
plot-p26-wt-cs-many: \
		$(PLOTSDIR)/bench_p26_wt_cs_many.svg

## Plot p26 write-throughput logging cache size benchmarks
.PHONY: plot-p26-wt-cs-logging
plot-p26-wt-cs-logging: \
		$(PLOTSDIR)/bench_p26_wt_cs_logging.svg



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
				-DERASE_SIZE='$(EMMC_ERASE_SIZE)' \
				-Dm=$5 \
				$(if $(filter amor,$6),--ylabel=raw) \
				$(if $(filter per,$6),--ylabel=total) \
				--title=sd/emmc \
				$(if $6,--add-xticklabel=,)" \
			$(if $6, \
			--subplot-below=" \
				-DERASE_SIZE='$(EMMC_ERASE_SIZE)' \
				-Dm=$5+$6 \
				$(if $(filter amor,$6),--ylabel=amortized) \
				$(if $(filter per,$6),--ylabel=per) \
				--ylim-stddev=3 \
				-H0.5",) \
		--subplot-right=" \
				-DERASE_SIZE='$(NOR_ERASE_SIZE)' \
				-Dm=$5 \
				--title=nor \
				$(if $6,--add-xticklabel=,) \
				-W0.5 \
			$(if $6, \
			--subplot-below=\" \
				-DERASE_SIZE='$(NOR_ERASE_SIZE)' \
				-Dm=$5+$6 \
				--ylim-stddev=3 \
				-H0.5\",)" \
		--subplot-right=" \
				-DERASE_SIZE='$(NAND_ERASE_SIZE)' \
				-Dm=$5 \
				--title=nand \
				$(if $6,--add-xticklabel=,) \
				-W0.33 \
			$(if $6, \
			--subplot-below=\" \
				-DERASE_SIZE='$(NAND_ERASE_SIZE)' \
				-Dm=$5+$6 \
				--ylim-stddev=3 \
				-H0.5\",)" \
		--legend \
		-L'3,$4_avg=lfs3%n$\
			- bs=$(EMMC_LFS3_BLOCK_SIZE)%n$\
			- bs=$(NOR_LFS3_BLOCK_SIZE)%n$\
			- bs=$(NAND_LFS3_BLOCK_SIZE)' \
		-L'3,$4_bnd=' \
		-L'30,$4_avg=lfs3nb%n$\
			- bs=$(EMMC_LFS3NB_BLOCK_SIZE)%n$\
			- bs=$(NOR_LFS3NB_BLOCK_SIZE)%n$\
			- bs=$(NAND_LFS3NB_BLOCK_SIZE)' \
		-L'30,$4_bnd=' \
		-L'2,$4_avg=lfs2%n$\
			- bs=$(EMMC_LFS2_BLOCK_SIZE)%n$\
			- bs=$(NOR_LFS2_BLOCK_SIZE)%n$\
			- bs=$(NAND_LFS2_BLOCK_SIZE)' \
		-L'2,$4_bnd=' \
		$(PLOT_COLORS_1BND) \
		$7 \
		$$(PLOTFLAGS) \
		-o$$@)
endef

$(eval $(call PLOT_P26_LITMUS_RULE,$\
		$(PLOTSDIR)/bench_p26_litmus_%_r.svg,$\
		$(foreach FS,lfs3 lfs3nb lfs2,$\
			$(foreach SIM,emmc nor nand,$\
				$(RESULTSDIR)/bench_p26_litmus_%.$(FS).$(SIM).avg.csv $\
				$(RESULTSDIR)/bench_p26_litmus_%.$(FS).$(SIM).amor.avg.csv)),$\
		"$$* file writes - reads",$\
		bench_readed,$\
		write,$\
		amor,$\
		-DMODE=0 --x2 --xunits=B --y2 --yunits=B))
$(eval $(call PLOT_P26_LITMUS_RULE,$\
		$(PLOTSDIR)/bench_p26_litmus_%_p.svg,$\
		$(foreach FS,lfs3 lfs3nb lfs2,$\
			$(foreach SIM,emmc nor nand,$\
				$(RESULTSDIR)/bench_p26_litmus_%.$(FS).$(SIM).avg.csv $\
				$(RESULTSDIR)/bench_p26_litmus_%.$(FS).$(SIM).amor.avg.csv)),$\
		"$$* file writes - progs",$\
		bench_proged,$\
		write,$\
		amor,$\
		-DMODE=0 --x2 --xunits=B --y2 --yunits=B))
$(eval $(call PLOT_P26_LITMUS_RULE,$\
		$(PLOTSDIR)/bench_p26_litmus_%_e.svg,$\
		$(foreach FS,lfs3 lfs3nb lfs2,$\
			$(foreach SIM,emmc nor nand,$\
				$(RESULTSDIR)/bench_p26_litmus_%.$(FS).$(SIM).avg.csv $\
				$(RESULTSDIR)/bench_p26_litmus_%.$(FS).$(SIM).amor.avg.csv)),$\
		"$$* file writes - erases",$\
		bench_erased,$\
		write,$\
		amor,$\
		-DMODE=0 --x2 --xunits=B --y2 --yunits=B))
$(eval $(call PLOT_P26_LITMUS_RULE,$\
		$(PLOTSDIR)/bench_p26_litmus_%_u.svg,$\
		$(foreach FS,lfs3 lfs3nb lfs2,$\
			$(foreach SIM,emmc nor nand,$\
				$(RESULTSDIR)/bench_p26_litmus_%.$(FS).$(SIM).avg.csv $\
				$(RESULTSDIR)/bench_p26_litmus_%.$(FS).$(SIM).per.avg.csv)),$\
		"$$* file usage",$\
		bench_readed,$\
		usage,$\
		per,$\
		-DMODE=1 --x2 --xunits=B --y2 --yunits=B))
$(eval $(call PLOT_P26_LITMUS_RULE,$\
		$(PLOTSDIR)/bench_p26_litmus_%.svg,$\
		$(foreach FS,lfs3 lfs3nb lfs2,$\
			$(foreach SIM,emmc nor nand,$\
				$(RESULTSDIR)/bench_p26_litmus_%.$(FS).$(SIM).sim.avg.csv $\
				$(RESULTSDIR)/bench_p26_litmus_%$\
					.$(FS).$(SIM).sim.amor.avg.csv)),$\
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
# $6 - extra plotmpl.py flags
#
define PLOT_P26_T_RULE
$1: $2
	$$(strip ./scripts/plotmpl.py $$^ \
		-W1500 -H350 \
		--title=$3 \
		-bFS \
		-x$4 \
		-ybench_readed \
		--subplot=" \
			-DERASE_SIZE=$(EMMC_ERASE_SIZE) \
			--title=sd/emmc" \
		--subplot-right=" \
			-DERASE_SIZE=$(NOR_ERASE_SIZE) \
			--title=nor \
			-W0.5" \
		--subplot-right=" \
			-DERASE_SIZE=$(NAND_ERASE_SIZE) \
			--title=nand \
			-W0.33" \
		--legend \
		-L3='lfs3%n$\
			- bs=$(EMMC_LFS3_BLOCK_SIZE)%n$\
			- bs=$(NOR_LFS3_BLOCK_SIZE)%n$\
			- bs=$(NAND_LFS3_BLOCK_SIZE)' \
		-L30='lfs3nb%n$\
			- bs=$(EMMC_LFS3NB_BLOCK_SIZE)%n$\
			- bs=$(NOR_LFS3NB_BLOCK_SIZE)%n$\
			- bs=$(NAND_LFS3NB_BLOCK_SIZE)' \
		-L2='lfs2%n$\
			- bs=$(EMMC_LFS2_BLOCK_SIZE)%n$\
			- bs=$(NOR_LFS2_BLOCK_SIZE)%n$\
			- bs=$(NAND_LFS2_BLOCK_SIZE)' \
		$(PLOT_COLORS_1) \
		-Fo- -F^- -Fs- -FX- -FP- \
		--xlog \
		--xticks=4 \
		-X"$$(shell python -c 'a=min([$5]); print(a-a/4)'),$\
			$$(shell python -c 'b=max([$5]); print(b+b/4)')" \
		--x2 --xunits=B \
		--y2 --yunits=B/s \
		$$(shell python -c '$\
			for n in [$5]: $\
				print("--add-xticklabel=%d=\"%%(x)IB\"" % n)') \
		$6 \
		$$(PLOTFLAGS) \
		-o$$@)
endef

$(eval $(call PLOT_P26_T_RULE,$\
		$(PLOTSDIR)/bench_p26_wt_%.svg,$\
		$(foreach FS,lfs3 lfs3nb lfs2,$\
			$(foreach SIM,emmc nor nand,$\
				$(RESULTSDIR)/bench_p26_wt_%.$(FS).$(SIM).tsim.csv)),$\
		"$$* file writes - simulated throughput",$\
		SIZE,$\
		$(P26_T_SIZES)))

$(eval $(call PLOT_P26_T_RULE,$\
		$(PLOTSDIR)/bench_p26_rt_%.svg,$\
		$(foreach FS,lfs3 lfs3nb lfs2,$\
			$(foreach SIM,emmc nor nand,$\
				$(RESULTSDIR)/bench_p26_rt_%.$(FS).$(SIM).tsim.csv)),$\
		"$$* file reads - simulated throughput",$\
		SIZE,$\
		$(P26_T_SIZES)))

$(eval $(call PLOT_P26_T_RULE,$\
		$(PLOTSDIR)/bench_p26_wt_bs_%.svg,$\
		$(foreach FS,lfs3 lfs3nb lfs2,$\
			$(foreach SIM,emmc nor nand,$\
				$(RESULTSDIR)/bench_p26_wt_bs_%.$(FS).$(SIM).tsim.csv)),$\
		"$$* file writes - block sizes - simulated throughput",$\
		BLOCK_SIZE,$\
		$(P26_T_BLOCK_SIZES),$\
		--xlabel="block size"))

$(eval $(call PLOT_P26_T_RULE,$\
		$(PLOTSDIR)/bench_p26_wt_ps_%.svg,$\
		$(foreach FS,lfs3 lfs3nb lfs2,$\
			$(foreach SIM,emmc nor nand,$\
				$(RESULTSDIR)/bench_p26_wt_ps_%.$(FS).$(SIM).tsim.csv)),$\
		"$$* file writes - read/prog sizes - simulated throughput",$\
		PAGE_SIZE,$\
		$(P26_T_PAGE_SIZES),$\
		--xlabel="read/prog size"))

$(eval $(call PLOT_P26_T_RULE,$\
		$(PLOTSDIR)/bench_p26_wt_cs_%.svg,$\
		$(foreach FS,lfs3 lfs3nb lfs2,$\
			$(foreach SIM,emmc nor nand,$\
				$(RESULTSDIR)/bench_p26_wt_cs_%.$(FS).$(SIM).tsim.csv)),$\
		"$$* file writes - cache sizes - simulated throughput",$\
		CACHE_SIZE,$\
		$(P26_T_CACHE_SIZES),$\
		--xlabel="cache size"))




#======================================================================#
# cleaning rules, we put everything in build dirs, so this is easy     #
#======================================================================#

## Clean everything
.PHONY: clean
clean: \
		clean-benches \
		clean-results \
		clean-codemaps \
		clean-plots

## Clean bench-runner things
.PHONY: clean-benches
clean-benches:
	rm -rf $(BUILDDIR)

## Clean bench results
.PHONY: clean-results
clean-results:
	rm -rf $(RESULTSDIR)

## Clean codemaps
.PHONY: clean-codemaps
clean-codemaps:
	rm -rf $(CODEMAPSDIR)

## Clean bench plots
.PHONY: clean-plots
clean-plots:
	rm -rf $(PLOTSDIR)

