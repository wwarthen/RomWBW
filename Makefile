.PHONY: tools source clean clobber diff transpile-c-code dist distlog config showconfig checkconfig

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

config:
	$(MAKE) --directory Source/HBIOS config

showconfig:
	$(MAKE) --directory Source/HBIOS showconfig

checkconfig:
	$(MAKE) --directory Source/HBIOS checkconfig

# Convert c code to assembly code
transpile-c-code:
	$(MAKE) -j --directory Source/HBIOS/ch376-native

dist:
	$(MAKE) ROM=dist
	$(MAKE) --directory Tools clean
	$(MAKE) --directory Source clean

distlog:
	time -p $(MAKE) dist 2>&1 | tee make.log
