OBJECTS = rom128_wbw.dat rom128_una.dat rom256_wbw.dat rom256_una.dat rom512_wbw.dat rom512_una.dat rom1024_wbw.dat rom1024_una.dat
OTHERS=*.dat

TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

.SHELLFLAGS = -ce

ROMAPPS1 := assign mode rtc syscopy xm
ROMAPPS2 := fdu format survey sysgen talk timer cpuspd

rom256_%.dat: ROMSIZ=256
rom512_%.dat: ROMSIZ=512
rom1024_%.dat: ROMSIZ=1024

rom256_%.dat: IMGSIZ=0x20000
rom512_%.dat: IMGSIZ=0x60000
rom1024_%.dat: IMGSIZ=0xE0000

rom256_%.dat: ROMAPPS=$(ROMAPPS1)
rom512_%.dat rom1024_%.dat: ROMAPPS=$(ROMAPPS1) $(ROMAPPS2)

rom%_wbw.dat: BIOS=wbw
rom%_una.dat: BIOS=una

rom128_%.dat:
	touch $@

%.dat:
	### Making ROM Disk $@
	srec_cat -Generate 0 $(IMGSIZ) --Constant 0xE5 -Output $@ -Binary
	$(CPMCP) -f wbw_rom$(ROMSIZ) $@ ROM_$(ROMSIZ)KB/*.* 0:
	for i in $(ROMAPPS) ; do $(CPMCP) -f wbw_rom$(ROMSIZ) $@ ../../Binary/Apps/$$i.com 0: ; done
	$(CPMCP) -f wbw_rom$(ROMSIZ) $@ ../CPM22/cpm_$(BIOS).sys 0:cpm.sys
	$(CPMCP) -f wbw_rom$(ROMSIZ) $@ ../ZSDOS/zsys_$(BIOS).sys 0:zsys.sys
	$(CPMCHATTR) -f wbw_rom$(ROMSIZ) $@ r 0:*.*
