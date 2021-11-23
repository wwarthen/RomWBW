OBJECTS = VGMPLAY.COM
DEST = ../../../Binary/Apps
TOOLS = ../../../Tools
OTHERS = *.LST

include $(TOOLS)/Makefile.inc

DEPS := VGMPLAY.ASM $(shell find . -name '*.inc')

VGMPLAY.COM: $(DEPS)
	$(TASM) -dWBW VGMPLAY.ASM VGMPLAY.COM VGMPLAY.LST

all::
	mkdir -p $(DEST)/Tunes
	cp Tunes/* $(DEST)/Tunes
