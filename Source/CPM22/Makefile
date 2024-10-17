SYSFILES = cpm_wbw.sys cpm_una.sys
BINFILES = cpm_wbw.bin cpm_una.bin
OBJECTS = CCP.bin BDOS.bin CCP22.bin BDOS22.bin OS2CCP.bin OS3BDOS.bin \
	ccpb03.bin bdosb01.bin loader.bin $(SYSFILES) $(BINFILES)
OTHERS = *.hex
NOCOPY = cpm_wbw.bin cpm_una.bin \
	CCP.bin BDOS.bin CCP22.bin BDOS22.bin OS2CCP.bin OS3BDOS.bin \
	ccpb03.bin bdosb01.bin loader.bin

DEST = ../../Binary/CPM22
TOOLS = ../../Tools

include $(TOOLS)/Makefile.inc

%.sys: %.bin loader.bin
	cat loader.bin $*.bin > $@

cpm_una.bin: OS2CCP.bin OS3BDOS.bin ../CBIOS/cbios_una.bin
	cat OS2CCP.bin OS3BDOS.bin ../CBIOS/cbios_una.bin > $@

cpm_wbw.bin: OS2CCP.bin OS3BDOS.bin ../CBIOS/cbios_wbw.bin
	cat OS2CCP.bin OS3BDOS.bin ../CBIOS/cbios_wbw.bin > $@
