OBJECTS = \
	font8x8u.asm font8x11u.asm font8x16u.asm \
	font8x8c.asm font8x11c.asm font8x16c.asm

OTHERS = font8x8c.bin font8x11c.bin font8x16c.bin

DEST = ../HBIOS
TOOLS = ../../Tools

include $(TOOLS)/Makefile.inc

#
# these 2 rules cancel out the default rules from the Makefile.inc
#
%.rel: %.asm
%.bin: %.asm

font8x8c.bin: font8x8u.bin
	$(BINDIR)/lzsa -f2 -r $< $@

font8x11c.bin: font8x11u.bin
	$(BINDIR)/lzsa -f2 -r $< $@

font8x16c.bin: font8x16u.bin
	$(BINDIR)/lzsa -f2 -r $< $@

%.asm: %.bin
	$(BINDIR)/bin2asm $< > $@
