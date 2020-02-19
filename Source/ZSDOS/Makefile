SYSFILES = zsys_wbw.sys zsys_una.sys
OBJECTS = $(SYSFILES)
OTHERS = zsdos.rel zsdos.err loader.bin
TOOLS = ../../Tools
CCP = ../ZCPR-DJ/zcpr.bin

include $(TOOLS)/Makefile.inc

zsdos.rel: zsdos.z80
	$(ZXCC) $(CPM)/ZMAC -$< -/P

zsdos.bin: zsdos.rel
	$(ZXCC) $(CPM)/LINK -$@=$<[LD800]

zsys_wbw.sys: loader.bin $(CCP) zsdos.bin ../CBIOS/cbios_wbw.bin
	cat loader.bin $(CCP) zsdos.bin ../CBIOS/cbios_wbw.bin > $@

zsys_una.sys: loader.bin $(CCP) zsdos.bin ../CBIOS/cbios_una.bin
	cat loader.bin $(CCP) zsdos.bin ../CBIOS/cbios_una.bin > $@

