OBJECTS = hdiag.com hdiag.rom
DEST = ../../Binary
TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

TASMFLAGS=-t hd64180

hdiag.com: hdiag.asm
	$(TASM) $(TASMFLAGS) -dAPPBOOT $< $@ hdiag.com.lst


hdiag.rom: hdiag.asm
	$(TASM) $(TASMFLAGS) -dROMBOOT $< $@ hdiag.rom.lst
