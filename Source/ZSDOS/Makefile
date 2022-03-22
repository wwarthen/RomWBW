SYSFILES = zsys_wbw.sys zsys_una.sys
BINFILES =  zsys_wbw.bin zsys_una.bin
OBJECTS = $(SYSFILES) $(BINFILES)
OTHERS = zsdos.rel zsdos.err loader.bin zsdos.bin
TOOLS = ../../Tools
CCP = ../ZCPR-DJ/zcpr.bin

include $(TOOLS)/Makefile.inc

zsdos.rel: zsdos.z80
	$(ZXCC) ZMAC -$< -/P

zsdos.bin: zsdos.rel
	$(ZXCC) LINK -$@=$<[LD800]

%.sys:	%.bin loader.bin
	cat loader.bin $*.bin > $@

zsys_wbw.bin: $(CCP) zsdos.bin ../CBIOS/cbios_wbw.bin
	cat $(CCP) zsdos.bin ../CBIOS/cbios_wbw.bin > $@

zsys_una.bin: $(CCP) zsdos.bin ../CBIOS/cbios_una.bin
	cat $(CCP) zsdos.bin ../CBIOS/cbios_una.bin > $@

