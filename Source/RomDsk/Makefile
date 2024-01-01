OBJECTS = rom128_wbw.dat rom128_una.dat rom256_wbw.dat rom256_una.dat rom512_wbw.dat rom512_una.dat rom1024_wbw.dat rom1024_una.dat ram512_wbw.dat ram1024_wbw.dat
OTHERS=*.dat

TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

.SHELLFLAGS = -ce

ROMAPPS1 := assign mode rtc syscopy xm
ROMAPPS2 := fdu format survey sysgen talk timer cpuspd

# rom256_%.dat: ROMSIZ=256
# rom512_%.dat: ROMSIZ=512
# rom1024_%.dat: ROMSIZ=1024

rom256_%.dat: DISKDEF=wbw_rom256
rom512_%.dat: DISKDEF=wbw_rom512
rom1024_%.dat: DISKDEF=wbw_rom1024
ram512_%.dat: DISKDEF=wbw_ram512
ram1024_%.dat: DISKDEF=wbw_ram1024

rom256_%.dat: DIR=ROM_256KB
rom512_%.dat: DIR=ROM_512KB
rom1024_%.dat: DIR=ROM_1024KB
ram512_%.dat: DIR=RAM_512KB
ram1024_%.dat: DIR=RAM_1024KB

rom256_%.dat: IMGSIZ=0x20000
rom512_%.dat: IMGSIZ=0x60000
rom1024_%.dat: IMGSIZ=0xE0000
ram512_%.dat: IMGSIZ=0x40000
ram1024_%.dat: IMGSIZ=0xC0000

rom256_%.dat: ROMAPPS=$(ROMAPPS1)
rom512_%.dat rom1024_%.dat: ROMAPPS=$(ROMAPPS1) $(ROMAPPS2)
ram512_%.dat ram1024_%.dat: ROMAPPS=$(ROMAPPS1) $(ROMAPPS2)

%_wbw.dat: BIOS=wbw
%_una.dat: BIOS=una

rom128_%.dat:
	touch $@

%.dat:
	### Making ROM Disk $@
	srec_cat -Generate 0 $(IMGSIZ) --Constant 0xE5 -Output $@ -Binary
	$(CPMCP) -f $(DISKDEF) $@ $(DIR)/*.* 0:
	for i in $(ROMAPPS) ; do $(CPMCP) -f $(DISKDEF) $@ ../../Binary/Apps/$$i.com 0: ; done
	$(CPMCP) -f $(DISKDEF) $@ ../CPM22/cpm_$(BIOS).sys 0:cpm.sys
	$(CPMCP) -f $(DISKDEF) $@ ../ZSDOS/zsys_$(BIOS).sys 0:zsys.sys
	$(CPMCHATTR) -f $(DISKDEF) $@ r 0:*.*
