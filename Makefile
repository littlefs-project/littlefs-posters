# overrideable build dir, default to ./build
BUILDDIR ?= build
# overrideable results dir, default to ./results
RESULTSDIR ?= results
# overrideable codemaps dir, defaults to ./codemaps
CODEMAPSDIR ?= codemaps
# overrideable plots dir, defaults ./plots
PLOTSDIR ?= plots

# how many samples to measure?
SAMPLES ?= 16

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
EMMC_LFS3_BLOCK_SIZE ?= 2048 # v3 performs better with larger block sizes
EMMC_LFS3NB_BLOCK_SIZE ?= 2048
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
BENCHES_LFS3 ?= benches/bench_p26.toml # TODO $(wildcard benches/*.toml)
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
BENCHES_LFS2 ?= benches/bench_p26.toml # TODO benches/bench_vs_lfs2.toml
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
		bench-p26-litmus

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


# p26 bench rules!

# p26 litmus bench rule
#
# $1 - target
# $2 - runner
# $3 - bench case
# $4 - read size
# $5 - prog size
# $6 - erase size
# $7 - block size, which may be different from erase size
#
define BENCH_P26_LITMUS_RULE
$1: $2
	$$(strip ./scripts/bench.py -R$$< -B $3 \
		-DSEED="range($$(SAMPLES))" \
		-DREAD_SIZE=$4 \
		-DPROG_SIZE=$5 \
		-DERASE_SIZE=$6 \
		-DBLOCK_SIZE=$7 \
		$$(BENCHFLAGS) \
		-o$$@)
endef

$(eval $(call BENCH_P26_LITMUS_RULE,$\
		$(RESULTSDIR)/bench_p26_litmus_%.lfs3.emmc.csv,$\
		$(BENCH_LFS3_RUNNER),$\
		bench_p26_litmus_$$*,$\
		$(EMMC_READ_SIZE),$\
		$(EMMC_PROG_SIZE),$\
		$(EMMC_ERASE_SIZE),$\
		$(EMMC_LFS3_BLOCK_SIZE)))
$(eval $(call BENCH_P26_LITMUS_RULE,$\
		$(RESULTSDIR)/bench_p26_litmus_%.lfs3.nor.csv,$\
		$(BENCH_LFS3_RUNNER),$\
		bench_p26_litmus_$$*,$\
		$(NOR_READ_SIZE),$\
		$(NOR_PROG_SIZE),$\
		$(NOR_ERASE_SIZE),$\
		$(NOR_LFS3_BLOCK_SIZE)))
$(eval $(call BENCH_P26_LITMUS_RULE,$\
		$(RESULTSDIR)/bench_p26_litmus_%.lfs3.nand.csv,$\
		$(BENCH_LFS3_RUNNER),$\
		bench_p26_litmus_$$*,$\
		$(NAND_READ_SIZE),$\
		$(NAND_PROG_SIZE),$\
		$(NAND_ERASE_SIZE),$\
		$(NAND_LFS3_BLOCK_SIZE)))

$(eval $(call BENCH_P26_LITMUS_RULE,$\
		$(RESULTSDIR)/bench_p26_litmus_%.lfs3nb.emmc.csv,$\
		$(BENCH_LFS3NB_RUNNER),$\
		bench_p26_litmus_$$*,$\
		$(EMMC_READ_SIZE),$\
		$(EMMC_PROG_SIZE),$\
		$(EMMC_ERASE_SIZE),$\
		$(EMMC_LFS3NB_BLOCK_SIZE)))
$(eval $(call BENCH_P26_LITMUS_RULE,$\
		$(RESULTSDIR)/bench_p26_litmus_%.lfs3nb.nor.csv,$\
		$(BENCH_LFS3NB_RUNNER),$\
		bench_p26_litmus_$$*,$\
		$(NOR_READ_SIZE),$\
		$(NOR_PROG_SIZE),$\
		$(NOR_ERASE_SIZE),$\
		$(NOR_LFS3NB_BLOCK_SIZE)))
$(eval $(call BENCH_P26_LITMUS_RULE,$\
		$(RESULTSDIR)/bench_p26_litmus_%.lfs3nb.nand.csv,$\
		$(BENCH_LFS3NB_RUNNER),$\
		bench_p26_litmus_$$*,$\
		$(NAND_READ_SIZE),$\
		$(NAND_PROG_SIZE),$\
		$(NAND_ERASE_SIZE),$\
		$(NAND_LFS3NB_BLOCK_SIZE)))

$(eval $(call BENCH_P26_LITMUS_RULE,$\
		$(RESULTSDIR)/bench_p26_litmus_%.lfs2.emmc.csv,$\
		$(BENCH_LFS2_RUNNER),$\
		bench_p26_litmus_$$*,$\
		$(EMMC_READ_SIZE),$\
		$(EMMC_PROG_SIZE),$\
		$(EMMC_ERASE_SIZE),$\
		$(EMMC_LFS2_BLOCK_SIZE)))
$(eval $(call BENCH_P26_LITMUS_RULE,$\
		$(RESULTSDIR)/bench_p26_litmus_%.lfs2.nor.csv,$\
		$(BENCH_LFS2_RUNNER),$\
		bench_p26_litmus_$$*,$\
		$(NOR_READ_SIZE),$\
		$(NOR_PROG_SIZE),$\
		$(NOR_ERASE_SIZE),$\
		$(NOR_LFS2_BLOCK_SIZE)))
$(eval $(call BENCH_P26_LITMUS_RULE,$\
		$(RESULTSDIR)/bench_p26_litmus_%.lfs2.nand.csv,$\
		$(BENCH_LFS2_RUNNER),$\
		bench_p26_litmus_$$*,$\
		$(NAND_READ_SIZE),$\
		$(NAND_PROG_SIZE),$\
		$(NAND_ERASE_SIZE),$\
		$(NAND_LFS2_BLOCK_SIZE)))

# simulated/estimated results
#
# $1 - target
# $2 - source
# $3 - read time
# $4 - prog time
# $5 - erase time
#
define BENCH_P26_SIM_RULE
$1: $2
	$$(strip ./scripts/csv.py $$^ \
		-Bm='%(m)s+sim' \
		-fbench_readed=' \
			(float(bench_readed)*float($3) \
				+ float(bench_proged)*float($4) \
				+ float(bench_erased)*float($5) \
				) / 1.0e9' \
		-fbench_proged=0 \
		-fbench_erased=0 \
		-fbench_creaded=' \
			(float(bench_creaded)*float($3) \
				+ float(bench_cproged)*float($4) \
				+ float(bench_cerased)*float($5) \
				) / 1.0e9' \
		-fbench_cproged=0 \
		-fbench_cerased=0 \
		-o$$@)
endef

$(eval $(call BENCH_P26_SIM_RULE,$\
		$(RESULTSDIR)/bench_%.emmc.sim.csv,$\
		$(RESULTSDIR)/bench_%.emmc.csv,$\
		$(EMMC_READ_TIME),$\
		$(EMMC_PROG_TIME),$\
		$(EMMC_ERASE_TIME)))
$(eval $(call BENCH_P26_SIM_RULE,$\
		$(RESULTSDIR)/bench_%.nor.sim.csv,$\
		$(RESULTSDIR)/bench_%.nor.csv,$\
		$(NOR_READ_TIME),$\
		$(NOR_PROG_TIME),$\
		$(NOR_ERASE_TIME)))
$(eval $(call BENCH_P26_SIM_RULE,$\
		$(RESULTSDIR)/bench_%.nand.sim.csv,$\
		$(RESULTSDIR)/bench_%.nand.csv,$\
		$(NAND_READ_TIME),$\
		$(NAND_PROG_TIME),$\
		$(NAND_ERASE_TIME)))

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
		plot-p26-litmus

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



# p26 plot rules!

# plot p26 config
#
# $1 - measurement
# $2 - optional amor/per flag
#
PLOT_P26_FLAGS += -W1500 -H700
PLOT_P26_FLAGS += \
		--subplot=" \
				-DERASE_SIZE='$(EMMC_ERASE_SIZE)' \
				-Dm=$1 \
				$(if $(filter amor,$2),--ylabel=raw) \
				$(if $(filter per,$2),--ylabel=total) \
				--title=sd/emmc \
				$(if $2,--add-xticklabel=,)" \
			$(if $2, \
			--subplot-below=" \
				-DERASE_SIZE='$(EMMC_ERASE_SIZE)' \
				-Dm=$1+$2 \
				$(if $(filter amor,$2),--ylabel=amortized) \
				$(if $(filter per,$2),--ylabel=per) \
				--ylim-stddev=3 \
				-H0.5",) \
		--subplot-right=" \
				-DERASE_SIZE='$(NOR_ERASE_SIZE)' \
				-Dm=$1 \
				--title=nor \
				$(if $2,--add-xticklabel=,) \
				-W0.5 \
			$(if $2, \
			--subplot-below=\" \
				-DERASE_SIZE='$(NOR_ERASE_SIZE)' \
				-Dm=$1+$2 \
				--ylim-stddev=3 \
				-H0.5\",)" \
		--subplot-right=" \
				-DERASE_SIZE='$(NAND_ERASE_SIZE)' \
				-Dm=$1 \
				--title=nand \
				$(if $2,--add-xticklabel=,) \
				-W0.33 \
			$(if $2, \
			--subplot-below=\" \
				-DERASE_SIZE='$(NAND_ERASE_SIZE)' \
				-Dm=$1+$2 \
				--ylim-stddev=3 \
				-H0.5\",)"
PLOT_P26_FLAGS += $(PLOT_COLORS_1BND)

# p26 litmus plot rule
#
# $1 - target
# $2 - sources, parameterized by $$(V) and $$(SIM)
# $3 - title
# $4 - y field
# $5 - measurement
# $6 - optional amor/per flag
# $7 - extra plotmpl.py flags
#
define PLOT_P26_LITMUS_RULE
$1: $$(foreach V, lfs3 lfs3nb lfs2, \
		$$(foreach SIM, emmc nor nand, $2))
	$$(strip ./scripts/plotmpl.py \
		<(./scripts/csv.py $$^ \
			-f$4_avg \
			-f$4_bnd=$4_min \
			-o-) \
		<(./scripts/csv.py $$^ \
			-D$4_avg='*' \
			-f$4_bnd=$4_max \
			-o-) \
		--title=$3 \
		-bV \
		-xn \
		-y$4_avg -y$4_bnd \
		--legend \
		-L'32,$4_avg=lfs3%n$\
			- bs=$(EMMC_LFS3_BLOCK_SIZE)%n$\
			- bs=$(NOR_LFS3_BLOCK_SIZE)%n$\
			- bs=$(NAND_LFS3_BLOCK_SIZE)' \
		-L'32,$4_bnd=' \
		-L'3,$4_avg=lfs3nb%n$\
			- bs=$(EMMC_LFS3NB_BLOCK_SIZE)%n$\
			- bs=$(NOR_LFS3NB_BLOCK_SIZE)%n$\
			- bs=$(NAND_LFS3NB_BLOCK_SIZE)' \
		-L'3,$4_bnd=' \
		-L'2,$4_avg=lfs2%n$\
			- bs=$(EMMC_LFS2_BLOCK_SIZE)%n$\
			- bs=$(NOR_LFS2_BLOCK_SIZE)%n$\
			- bs=$(NAND_LFS2_BLOCK_SIZE)' \
		-L'2,$4_bnd=' \
		$$(call PLOT_P26_FLAGS,$5,$6) \
		$7 \
		$$(PLOTFLAGS) \
		-o$$@)
endef

# lfs3 vs lfs3nb vs lfs2 - linear file writes
$(eval $(call PLOT_P26_LITMUS_RULE,$\
		$(PLOTSDIR)/bench_p26_litmus_%_r.svg,$\
		$(RESULTSDIR)/bench_p26_litmus_%.$$(V).$$(SIM).avg.csv $\
			$(RESULTSDIR)/bench_p26_litmus_%.$$(V).$$(SIM).amor.avg.csv,$\
		"lfs3 vs lfs3nb vs lfs2 - $$* file writes - reads",$\
		bench_readed,$\
		write,$\
		amor,$\
		-DMODE=0 --x2 --xunits=B --y2 --yunits=B))
$(eval $(call PLOT_P26_LITMUS_RULE,$\
		$(PLOTSDIR)/bench_p26_litmus_%_p.svg,$\
		$(RESULTSDIR)/bench_p26_litmus_%.$$(V).$$(SIM).avg.csv $\
			$(RESULTSDIR)/bench_p26_litmus_%.$$(V).$$(SIM).amor.avg.csv,$\
		"lfs3 vs lfs3nb vs lfs2 - $$* file writes - progs",$\
		bench_proged,$\
		write,$\
		amor,$\
		-DMODE=0 --x2 --xunits=B --y2 --yunits=B))
$(eval $(call PLOT_P26_LITMUS_RULE,$\
		$(PLOTSDIR)/bench_p26_litmus_%_e.svg,$\
		$(RESULTSDIR)/bench_p26_litmus_%.$$(V).$$(SIM).avg.csv $\
			$(RESULTSDIR)/bench_p26_litmus_%.$$(V).$$(SIM).amor.avg.csv,$\
		"lfs3 vs lfs3nb vs lfs2 - $$* file writes - erases",$\
		bench_erased,$\
		write,$\
		amor,$\
		-DMODE=0 --x2 --xunits=B --y2 --yunits=B))
$(eval $(call PLOT_P26_LITMUS_RULE,$\
		$(PLOTSDIR)/bench_p26_litmus_%_u.svg,$\
		$(RESULTSDIR)/bench_p26_litmus_%.$$(V).$$(SIM).avg.csv $\
			$(RESULTSDIR)/bench_p26_litmus_%.$$(V).$$(SIM).per.avg.csv,$\
		"lfs3 vs lfs3nb vs lfs2 - $$* file usage",$\
		bench_readed,$\
		usage,$\
		per,$\
		-DMODE=1 --x2 --xunits=B --y2 --yunits=B))
$(eval $(call PLOT_P26_LITMUS_RULE,$\
		$(PLOTSDIR)/bench_p26_litmus_%.svg,$\
		$(RESULTSDIR)/bench_p26_litmus_%.$$(V).$$(SIM).sim.avg.csv $\
			$(RESULTSDIR)/bench_p26_litmus_%.$$(V).$$(SIM).sim.amor.avg.csv,$\
		"lfs3 vs lfs3nb vs lfs2 - $$* file writes - simulated runtime",$\
		bench_readed,$\
		write+sim,$\
		amor,$\
		-DMODE=0 --x2 --xunits=B --yunits=s))




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

