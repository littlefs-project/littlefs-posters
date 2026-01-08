# various directories
BUILDDIR ?= build
# port for local http server
PORT ?= 2026

# default target
POSTER ?= $(BUILDDIR)/littlefs-btree-poster.pdf
ABSTRACT ?= $(BUILDDIR)/littlefs-btree-abstract.pdf
TARGET ?= $(POSTER) $(ABSTRACT)
SRC += $(POSTER:$(BUILDDIR)/%.pdf=%.tex) $(ABSTRACT:$(BUILDDIR)/%.pdf=%.tex)
SRC += littlefs-btree-abstract.bib
SRC += littlefs-poster.cls
SRC += littlefs-ico.tex
SRC += usenix-2020-09.sty

# where are our benchmarks?
BENCHMARKSDIR ?= benchmarks
# where do we put results?
RESULTSDIR ?= results


# fix timestamps to try to preserve current page in pdf viewers
#
# https://github.com/mozilla/pdf.js/issues/11359#issuecomment-558841393
#
export SOURCE_DATE_EPOCH ?= 0

# pdflatex
PDFLATEX ?= pdflatex
PDFLATEXFLAGS += -output-directory=$(BUILDDIR)
PDFLATEXFLAGS += -file-line-error
PDFLATEXFLAGS += -interaction=nonstopmode
PDFLATEXFLAGS += -halt-on-error

# bibtex
BIBTEX ?= bibtex

# wristwatch script
WRISTWATCH ?= ./scripts/wristwatch.py
WRISTWATCHFLAGS += -I$(BUILDDIR)
WRISTWATCHFLAGS += -I$(BENCHMARKSDIR)
WRISTWATCHFLAGS += -w0.5
ifdef VERBOSE
WRISTWATCHFLAGS += -v
endif


# this is a bit of a hack, but we want to make sure BUILDDIR exists
# before running any commands
ifneq ($(BUILDDIR),.)
$(if $(findstring n,$(MAKEFLAGS)),, $(shell mkdir -p $(BUILDDIR)))
endif


## Build things, may need to build ~3x to resolve refs!
.PHONY: all build
all build: $(TARGET)

## Find word counts
.PHONY: count
count:
	texcount $(SRC)

## Edit the main document
# this is really just an example of explicitly loading the .vimrc
.PHONY: vim
vim:
	vim -S .vimrc $(firstword $(SRC))

# build .pdf from .tex
$(POSTER): $(POSTER:$(BUILDDIR)/%.pdf=%.tex) $(SRC)
	$(PDFLATEX) $(PDFLATEXFLAGS) $<

$(ABSTRACT): $(ABSTRACT:$(BUILDDIR)/%.pdf=%.tex) $(SRC)
	$(PDFLATEX) $(PDFLATEXFLAGS) $<
	$(BIBTEX) $(ABSTRACT:.pdf=.aux)

## Run a local server
.PHONY: serve server
serve server:
	python -m http.server $(PORT)

## Rebuild on changes
.PHONY: watch
watch:
	$(WRISTWATCH) $(WRISTWATCHFLAGS) make

## Run a local server and rebuild on changes
.PHONY: watch-serve watch-server
watch-serve watch-server:
	$(WRISTWATCH) $(WRISTWATCHFLAGS) -s:$(PORT) make

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

## Copy results from benchmarks
.PHONY: sync-results
sync-results:
	mkdir -p $(RESULTSDIR)
	-cp -u $(BENCHMARKSDIR)/tikz_1M/*.csv $(RESULTSDIR)
	-cp -u $(BENCHMARKSDIR)/tikz_1G/*.csv $(RESULTSDIR)
	-cp -u $(BENCHMARKSDIR)/tikz_x_ds/*.csv $(RESULTSDIR)
	-cp -u $(BENCHMARKSDIR)/tikz_x_bs/*.csv $(RESULTSDIR)
	-cp -u $(BENCHMARKSDIR)/tikz_x_gs/*.csv $(RESULTSDIR)
	-cp -u $(BENCHMARKSDIR)/tikz_x_rs/*.csv $(RESULTSDIR)
	-cp -u $(BENCHMARKSDIR)/tikz_x_ps/*.csv $(RESULTSDIR)
	-cp -u $(BENCHMARKSDIR)/tikz_x_mr/*.csv $(RESULTSDIR)
	-cp -u $(BENCHMARKSDIR)/tikz_x_n_1G/*.csv $(RESULTSDIR)
	-cp -u $(BENCHMARKSDIR)/tikz_y_ct/*.csv $(RESULTSDIR)
	-cp -u $(BENCHMARKSDIR)/tikz_y_fs/*.csv $(RESULTSDIR)
	-cp -u $(BENCHMARKSDIR)/tikz_y_ss_n/*.csv $(RESULTSDIR)
	-cp -u $(BENCHMARKSDIR)/tikz_y_ss_mr/*.csv $(RESULTSDIR)
	-cp -u $(BENCHMARKSDIR)/tikz_y_ls_1G/*.csv $(RESULTSDIR)
	-cp -u $(BENCHMARKSDIR)/tikz_y_br_gs/*.csv $(RESULTSDIR)
	-cp -u $(BENCHMARKSDIR)/tikz_y_ct_n/*.csv $(RESULTSDIR)
	-cp -u $(BENCHMARKSDIR)/tikz_y_cs/*.csv $(RESULTSDIR)


## Clean everything (except results)
.PHONY: clean
clean:
	rm -rf $(BUILDDIR)

