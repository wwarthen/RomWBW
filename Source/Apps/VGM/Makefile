OBJECTS = vgmplay.com
DEST = ../../../Binary/Apps
TOOLS = ../../../Tools
OTHERS = *.LST

include $(TOOLS)/Makefile.inc

DEPS := vgmplay.asm $(shell find . -name '*.inc')

vgmplay.com: $(DEPS)
	$(TASM) -dWBW vgmplay.asm vgmplay.com vgmplay.lst

ym2612.com: 
	$(TASM) -dWBW ym2612.asm ym2612.com ym2612.lst

all::
	mkdir -p $(DEST)/Tunes
	cp Tunes/* $(DEST)/Tunes
