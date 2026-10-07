FPC ?= fpc
SRC := src/gtm.lpr
BIN := bin/gtm

.PHONY: all cli gui clean

all: cli

cli: $(BIN)

$(BIN): $(SRC) core/gtmcore.pas
	mkdir -p bin
	$(FPC) -Fucore -FEbin -FUbin $(SRC)

gui:
	mkdir -p bin
	lazbuild gui/gtm-gui.lpi

clean:
	rm -rf bin
	rm -rf gui/lib
