OBJECTS = tune.com tunezx.com tunemsx.com
DEST = ../../../Binary/Apps
TOOLS = ../../../Tools

include $(TOOLS)/Makefile.inc

DEPS := tune.asm $(shell find . -name '*.inc')

tune.com: $(DEPS)
	$(TASM) -dWBW tune.asm tune.com tune.lst

tunezx.com: $(DEPS)
	$(TASM) -dZX tune.asm tunezx.com tunezx.lst

tunemsx.com: $(DEPS)
	$(TASM) -dMSX tune.asm tunemsx.com tunemsx.lst

all::
	mkdir -p $(DEST)/Tunes
	cp Tunes/* $(DEST)/Tunes
