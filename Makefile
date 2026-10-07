FPC ?= fpc
SRC := src/gtm.lpr
BIN := bin/gtm

VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
VERSION_INC := bin/gtmversion.inc

DIST_PARENT ?= $(abspath ..)
SOURCE_DIR_NAME := $(notdir $(CURDIR))
BASELINE_NAME := gtm-baseline-$(VERSION)
BASELINE_ARCHIVE := $(DIST_PARENT)/$(BASELINE_NAME).tar.gz

.PHONY: all cli gui clean baseline version

all: cli

version:
	@mkdir -p bin
	@printf "const GTMVersion = '%s';\n" "$(VERSION)" > "$(VERSION_INC)"

cli: version
	mkdir -p bin
	$(FPC) -Fucore -FEbin -FUbin -Fibin $(SRC)

gui: version
	mkdir -p bin
	lazbuild gui/gtm-gui.lpi

clean:
	rm -rf bin
	rm -rf gui/lib

baseline:
	@set -eu; \
	rm -f "$(BASELINE_ARCHIVE)"; \
	tar -C "$(DIST_PARENT)" \
		--exclude="$(SOURCE_DIR_NAME)/bin" \
		--exclude="$(SOURCE_DIR_NAME)/gui/lib" \
		--exclude='*.o' \
		--exclude='*.ppu' \
		--exclude='*.compiled' \
		-czf "$(BASELINE_ARCHIVE)" "$(SOURCE_DIR_NAME)"; \
	tar -tzf "$(BASELINE_ARCHIVE)" | grep -q "^$(SOURCE_DIR_NAME)/\.git/" || { \
		echo "baseline: archive is missing .git" >&2; exit 1; \
	}; \
	if tar -tzf "$(BASELINE_ARCHIVE)" | grep -Eq "^$(SOURCE_DIR_NAME)/(bin|gui/lib)(/|$$)"; then \
		echo "baseline: archive unexpectedly contains build products" >&2; exit 1; \
	fi; \
	echo "$(BASELINE_ARCHIVE)"
