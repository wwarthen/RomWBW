OBJECTS = \
	font8x8u.asm font8x11u.asm font8x16u.asm \
	font8x8c.asm font8x11c.asm font8x16c.asm

DEST = ../HBIOS
TOOLS = ../../Tools
OTHERS = *.rel

include $(TOOLS)/Makefile.inc

#
# these 2 rules cancel out the default rules from the Makefile.inc
#
%.rel: %.asm
%.bin: %.asm

%.asm: %.bin
	$(BINDIR)/bin2asm $< > $@
