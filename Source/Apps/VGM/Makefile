OBJECTS = vgmplay.com
DEST = ../../../Binary/Apps
TOOLS = ../../../Tools
OTHERS = *.LST

include $(TOOLS)/Makefile.inc

DEPS := vgmplay.asm $(shell find . -name '*.inc')

vgmplay.com: $(DEPS)
	$(TASM) -dWBW vgmplay.asm vgmplay.com vgmplay.lst

all::
	mkdir -p $(DEST)/Tunes
	cp Tunes/* $(DEST)/Tunes
