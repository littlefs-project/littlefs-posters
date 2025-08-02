# overrideable build dir, default to ./build_1M
export BUILDDIR ?= build_1M
# overrideable results dir, default to ./results_1M
export RESULTSDIR ?= results_1M
# overrideable plots dir, defaults ./plots_1M
export PLOTSDIR ?= plots_1M


# and give us more space for activities
export DISK_SIZE ?= 268435456

# increase bench sizes to 1 MiB
export P26_LITMUS_SIZE ?= 1048576
export P26_LITMUS_STEP ?= 64
export P26_T_SIZES ?= 32768,65536,131072,262144,524288,1048576


# don't run rules in parallel at this level, it breaks things
.NOTPARALLEL:

# we just set the above defines, the default Makefile does all the
# real work
FORCE:;
%: FORCE
	@$(MAKE) $@

