FPC ?= fpc
GO ?= go
MOUNT_BIN := bin/gtm-mount
TUI_SRC := tui/gtm-tui.lpr

VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
VERSION_INC := bin/gtmversion.inc

DIST_PARENT ?= $(abspath ..)
SOURCE_DIR_NAME := $(notdir $(CURDIR))
BASELINE_NAME := gtm-baseline-$(VERSION)
BASELINE_ARCHIVE := $(DIST_PARENT)/$(BASELINE_NAME).tar.gz

PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
INSTALL ?= install

.PHONY: all gui tui mount install clean repo-clean repo-purge-binaries baseline version

all: gui tui mount

version:
	@mkdir -p bin
	@printf "const GTMVersion = '%s';\n" "$(VERSION)" > "$(VERSION_INC)"

gui: version
	mkdir -p bin
	lazbuild gui/gtm-gui.lpi

tui: version
	mkdir -p bin
	$(FPC) -Fucore -Futui -FEbin -FUbin -Fibin $(TUI_SRC)


mount:
	mkdir -p bin
	$(GO) build -o $(MOUNT_BIN) ./mount

install: all
	$(INSTALL) -d "$(DESTDIR)$(BINDIR)"
	$(INSTALL) -m 755 bin/gtm-gui bin/gtm-tui bin/gtm-mount "$(DESTDIR)$(BINDIR)/"

clean:
	rm -rf bin
	rm -rf gui/lib
	rm -rf gui/backup
	rm -f gui/*.lps gui/*.res

# Current-tree cleanup only. History is unchanged.
repo-clean:
	git rm -r --cached --ignore-unmatch bin gui/lib gui/backup
	git rm --cached --ignore-unmatch gui/*.lps gui/*.res
	git rm --cached --ignore-unmatch '*.o' '*.ppu' '*.compiled'

# One-time repository surgery: remove all build/binary artifacts from every
# reachable branch/tag, then repack. Creates a bundle backup beside the repo.
repo-purge-binaries:
	./tools/purge-binaries-from-history.sh

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
