.PHONY: tools source clean clobber diff dist

.ONESHELL:
.SHELLFLAGS = -ce

all: tools source

tools:
	$(MAKE) --directory Tools

source:
	$(MAKE) --directory Source

clean:
	$(MAKE) --directory Tools clean
	$(MAKE) --directory Source clean
	$(MAKE) --directory Binary clean
	rm -f make.log

clobber: clean

diff:
	$(MAKE) --directory Source diff

# Convert c code to assembly code
transpile-c-code:
	@cd Source/HBIOS/ch376-native
	$(MAKE) -j

dist:
	$(MAKE) ROM_PLATFORM=dist
	$(MAKE) --directory Tools clean
	$(MAKE) --directory Source clean

distlog:
	time -p $(MAKE) dist 2>&1 | tee make.log
