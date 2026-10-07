FPC ?= fpc
SRC := src/gtm.lpr
BIN := bin/gtm

.PHONY: all clean

all: $(BIN)

$(BIN): $(SRC) core/gtmcore.pas
	mkdir -p bin
	$(FPC) -Fucore -FEbin -FUbin $(SRC)

clean:
	rm -rf bin
