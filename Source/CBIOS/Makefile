OBJECTS = cbios_wbw.bin cbios_una.bin
TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

cbios_wbw.bin: cbios.asm 
	$(TASM) -dPLTWBW $< $@ cbios_wbw.lst

cbios_una.bin: cbios.asm
	$(TASM) -dPLTUNA $< $@ cbios_una.lst

