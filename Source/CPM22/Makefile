SYSFILES = cpm_wbw.sys cpm_una.sys
OBJECTS = CCP.bin BDOS.bin CCP22.bin BDOS22.bin OS2CCP.bin OS3BDOS.bin \
	ccpb03.bin bdosb01.bin loader.bin $(SYSFILES)
OTHERS = *.hex
TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

cpm_wbw.sys: loader.bin OS2CCP.bin OS3BDOS.bin ../CBIOS/cbios_wbw.bin
	cat loader.bin OS2CCP.bin OS3BDOS.bin ../CBIOS/cbios_wbw.bin > $@

cpm_una.sys: loader.bin OS2CCP.bin OS3BDOS.bin ../CBIOS/cbios_una.bin
	cat loader.bin OS2CCP.bin OS3BDOS.bin ../CBIOS/cbios_una.bin > $@
