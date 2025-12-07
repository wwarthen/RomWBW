OBJECTS = vgmplay.com vgminfo.com
DEST = ../../../Binary/Apps
TOOLS = ../../../Tools
OTHERS = *.LST

include $(TOOLS)/Makefile.inc

DEPS := vgmplay.asm $(shell find . -name '*.inc')

vgmplay.com: $(DEPS)
	$(TASM) -dWBW vgmplay.asm vgmplay.com vgmplay.lst

ym2612.com: 
	$(TASM) -dWBW ymfmdemo.asm ymfmdemo.com ymfmdemo.lst

vgminfo.com: 
	$(TASM) -dWBW vgminfo.asm vgminfo.com vgminfo.lst

all::
	mkdir -p $(DEST)/Tunes
	cp Tunes/*.vgm $(DEST)/Tunes
