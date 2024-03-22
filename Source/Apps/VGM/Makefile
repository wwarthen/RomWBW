OBJECTS = vgmplay.com
DEST = ../../../Binary/Apps
TOOLS = ../../../Tools
OTHERS = *.LST

include $(TOOLS)/Makefile.inc

DEPS := vgmplay.asm $(shell find . -name '*.inc')

vgmplay.com: $(DEPS)
	$(TASM) -dWBW vgmplay.asm vgmplay.com vgmplay.lst

ym2612.com: 
	$(TASM) -dWBW ymfmdemo.asm ymfmdemo.com ymfmdemo.lst

all::
	mkdir -p $(DEST)/Tunes
	cp Tunes/*.vgm $(DEST)/Tunes
