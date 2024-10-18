SYSFILES = qpm_wbw.sys qpm_una.sys
BINFILES = qpm_wbw.bin qpm_una.bin
OBJECTS = loader.bin $(SYSFILES) $(BINFILES)
OTHERS = *.hex
NOCOPY = qpm_wbw.bin qpm_una.bin loader.bin loader.lst
DEST = ../../Binary/QPM
TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

%.sys: %.bin loader.bin
	cat loader.bin $*.bin > $@

qpm_una.bin: qcp27.dat qdos27.dat ../CBIOS/cbios_una.bin
	cat qcp27.dat qdos27.dat ../CBIOS/cbios_una.bin > $@

qpm_wbw.bin: qcp27.dat qdos27.dat ../CBIOS/cbios_wbw.bin
	cat qcp27.dat qdos27.dat ../CBIOS/cbios_wbw.bin > $@
