
MOREDIFF = camel80.bin game.bin hbios_rom.bin nascom.bin prefix.bin usrrom.bin \
	dbgmon.bin hbios_app.bin imgpad2.bin osimg1.bin osimg2.bin romldr.bin \
	eastaegg.bin hbios_img.bin osimg.bin tastybasic.bin \
	game.bin updater.bin usrrom.bin

SUBDIRS =
DEST = ../../Binary
TOOLS =../../Tools
OTHERS =  *.img *.rom *.com *.upd *.bin *.z80 cpm.sys zsys.sys Build.inc font*.asm *.dat
include $(TOOLS)/Makefile.inc

FONTS := font8x11c.asm font8x11u.asm font8x16c.asm font8x16u.asm font8x8c.asm font8x8u.asm

ifneq ($(findstring $(ROM_PLATFORM), N8 MK4 RCZ180 SCZ180 DYNO),)
	TASM=$(BINDIR)/uz80as -t hd64180
endif

ifneq ($(findstring $(ROM_PLATFORM), RCZ280),)
	TASM=$(BINDIR)/uz80as -t z280
endif

ifeq ($(DIFFMAKE),1)
	DIFFBUILD := -d $(DIFFTO)/Source/HBIOS
endif

DIFFPATH = $(DIFFTO)/Binary

DEPS=prereq dbgmon.bin romldr.bin nascom.bin tastybasic.bin game.bin eastaegg.bin updater.bin usrrom.bin imgpad2.bin

ifeq ($(ROM_PLATFORM),UNA)
	ROMDEPS=romldr.bin dbgmon.bin
	BIOS=una
else
	ROMDEPS=hbios_rom.bin hbios_app.bin hbios_img.bin
	BIOS=wbw
endif

ROMNAME=${ROM_PLATFORM}_${ROM_CONFIG}

#$(info DEPS=$(DEPS))
#$(info ROM_PLATFORM=$(ROM_PLATFORM))
#$(info ROM_CONFIG=$(ROM_CONFIG))
#$(info ROMSIZE=$(ROMSIZE))
#$(info ROMNAME=$(ROMNAME))

all::
	if [ -z "$(OBJECTS)" ] ; then \
		chmod +x Build.sh ; \
		bash Build.sh ; \
	fi

$(ROMNAME).rom $(ROMNAME).com $(ROMNAME).img &: $(ROMDEPS)
	cat romldr.bin dbgmon.bin ../ZSDOS/zsys_$(BIOS).bin ../CPM22/cpm_$(BIOS).bin >osimg.bin
	cat romldr.bin dbgmon.bin ../ZSDOS/zsys_$(BIOS).bin >osimg_small.bin
	if [ $(ROM_PLATFORM) != UNA ] ; then \
		cat camel80.bin nascom.bin tastybasic.bin game.bin eastaegg.bin netboot.mod updater.bin usrrom.bin >osimg1.bin ; \
		cat imgpad2.bin >osimg2.bin ; \
		for f in hbios_rom.bin osimg.bin osimg1.bin osimg2.bin ; do \
			srec_cat $$f -Binary -Crop 0 0x7FFF -Checksum_Negative_Big_Endian 0x7FFF 1 1 -o $$f -Binary ; \
		done \
	fi
	if [ $(ROM_PLATFORM) = UNA ] ; then \
		cp osimg.bin $(DEST)/UNA_WBW_SYS.bin ; \
		cp ../RomDsk/rom$(ROMSIZE)_una.dat $(DEST)/UNA_WBW_ROM$(ROMSIZE).bin ; \
		cat ../UBIOS/UNA-BIOS.BIN osimg.bin ../UBIOS/FSFAT.BIN ../RomDsk/rom$(ROMSIZE)_una.dat >$(ROMNAME).rom ; \
	else \
		cat hbios_rom.bin osimg.bin osimg1.bin osimg2.bin ../RomDsk/rom$(ROMSIZE)_wbw.dat >$(ROMNAME).rom ; \
		cat hbios_rom.bin osimg.bin osimg1.bin osimg2.bin >$(ROMNAME).upd ; \
		cat hbios_app.bin osimg_small.bin > $(ROMNAME).com ; \
	fi

prereq: $(FONTS) camel80.bin

font%.asm:
	cp ../Fonts/$@ .

camel80.bin:
	cp ../Forth/$@ .
	
hbios_rom.bin:	hbios.asm build.inc  $(DEPS)
	$(TASM) -dROMBOOT hbios.asm hbios_rom.bin hbios_rom.lst

hbios_app.bin:	hbios.asm build.inc  $(DEPS)
	$(TASM) -dAPPBOOT hbios.asm hbios_app.bin hbios_app.lst

hbios_img.bin:	hbios.asm build.inc  $(DEPS)
	$(TASM) -dIMGBOOT hbios.asm hbios_img.bin hbios_img.lst

romldr.bin:	build.inc
dbgmon.bin:	build.inc
nascom.bin:	build.inc
eastaegg.bin:	build.inc
updater.bin:	build.inc

dumps:
	for i in $(MOREDIFF) ; do \
		hexdump -C $$i >$$i.dump ; \
	done
