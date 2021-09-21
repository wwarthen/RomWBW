OBJECTS = hdiag.com hdiag.rom
DEST = ../../Binary
TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

TASMFLAGS=-t hd64180

hdiag.com: hdiag.asm
	$(TASM) $(TASMFLAGS) -dAPPBOOT $< $@ $*.lst


hdiag.rom: hdiag.asm
	$(TASM) $(TASMFLAGS) -dROMBOOT $< $@ $*.lst

#cbios_wbw.bin: cbios.asm 
#	$(TASM) -dPLTWBW $< $@ cbios_wbw.lst
#
#cbios_una.bin: cbios.asm
#	$(TASM) -dPLTUNA $< $@ cbios_una.lst

