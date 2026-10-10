FPC ?= fpc
SRC := src/gtm.lpr
BIN := bin/gtm
GO ?= go
MOUNT_BIN := bin/gtm-mount
TUI_SRC := tui/gtm-tui.lpr

VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
VERSION_INC := bin/gtmversion.inc

DIST_PARENT ?= $(abspath ..)
SOURCE_DIR_NAME := $(notdir $(CURDIR))
BASELINE_NAME := gtm-baseline-$(VERSION)
BASELINE_ARCHIVE := $(DIST_PARENT)/$(BASELINE_NAME).tar.gz

.PHONY: all cli gui tui mount clean repo-clean baseline version

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

tui: version
	mkdir -p bin
	$(FPC) -Fucore -Futui -FEbin -FUbin -Fibin $(TUI_SRC)


mount:
	mkdir -p bin
	$(GO) build -o $(MOUNT_BIN) ./mount

clean:
	rm -rf bin
	rm -rf gui/lib
	rm -rf gui/backup
	rm -f gui/*.lps gui/*.res

# One-time source-control cleanup: stop tracking generated/editor files.
repo-clean:
	git rm -r --cached --ignore-unmatch bin gui/lib gui/backup
	git rm --cached --ignore-unmatch gui/*.lps gui/*.res
	git rm --cached --ignore-unmatch '*.o' '*.ppu' '*.compiled'

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
