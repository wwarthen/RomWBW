OBJECTS = rom0_wbw.dat rom0_una.dat rom128_wbw.dat rom128_una.dat rom256_wbw.dat rom256_una.dat rom384_wbw.dat rom384_una.dat rom896_wbw.dat rom896_una.dat
OTHERS=*.dat *.cat

TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

.SHELLFLAGS = -ce

ROMAPPS1 := assign mode rtc syscopy xm
ROMAPPS2 := fdu format survey sysgen talk timer cpuspd reboot

rom128_%.dat: DISKDEF=wbw_rom128
rom256_%.dat: DISKDEF=wbw_rom256
rom384_%.dat: DISKDEF=wbw_rom384
rom896_%.dat: DISKDEF=wbw_rom896

rom128_%.dat: DIR=ROM_128KB
rom256_%.dat: DIR=ROM_256KB
rom384_%.dat: DIR=ROM_384KB
rom896_%.dat: DIR=ROM_896KB

rom128_%.dat: IMGSIZ=0x20000
rom256_%.dat: IMGSIZ=0x40000
rom384_%.dat: IMGSIZ=0x60000
rom896_%.dat: IMGSIZ=0xE0000

rom128_%.dat: ROMAPPS=$(ROMAPPS1)
rom256_%.dat rom384_%.dat rom896_%.dat: ROMAPPS=$(ROMAPPS1) $(ROMAPPS2)

%_wbw.dat: BIOS=wbw
%_una.dat: BIOS=una

rom0_%.dat:
	touch $@

%.dat:
	### Making ROM Disk $@
	srec_cat -Generate 0 $(IMGSIZ) --Constant 0xE5 -Output $@ -Binary
	$(CPMCP) -f $(DISKDEF) $@ $(DIR)/*.* 0:
	for i in $(ROMAPPS) ; do $(CPMCP) -f $(DISKDEF) $@ ../../Binary/Apps/$$i.com 0: ; done
	$(CPMCP) -f $(DISKDEF) $@ ../CPM22/cpm_$(BIOS).sys 0:cpm.sys
	$(CPMCP) -f $(DISKDEF) $@ ../ZSDOS/zsys_$(BIOS).sys 0:zsys.sys
	$(CPMCHATTR) -f $(DISKDEF) $@ r 0:*.*
	$(CPMLS) -f $(DISKDEF) -D $@ > $(@:.dat=.cat)
