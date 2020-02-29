OBJECTS =

ifeq (1,1)
OBJECTS += DYNO_std.rom
OBJECTS += EZZ80_std.rom
OBJECTS += MK4_std.rom
OBJECTS += N8_std.rom
OBJECTS += RCZ180_ext.rom
OBJECTS += RCZ180_nat.rom
#OBJECTS += RCZ80_kio.rom
#OBJECTS += RCZ80_mt.rom
#OBJECTS += RCZ80_std.rom
#OBJECTS += RCZ80_wiz.rom
#OBJECTS += SBC_simh.rom
#OBJECTS += SBC_std.rom 
#OBJECTS += SCZ180_126.rom
#OBJECTS += SCZ180_130.rom
#OBJECTS += UNA_std.rom
#OBJECTS += ZETA_std.rom
#OBJECTS += ZETA2_std.rom
else
OBJECTS += ZETA_std.rom
OBJECTS += ZETA2_std.rom
endif

MOREDIFF = camel80.bin game.bin hbios_rom.bin nascom.bin prefix.bin usrrom.bin \
	dbgmon.bin hbios_app.bin imgpad0.bin osimg1.bin romldr.bin \
	eastaegg.bin hbios_img.bin imgpad.bin osimg.bin tastybasic.bin \
	game.bin usrrom.bin

SUBDIRS = 
DEST = ../../Binary
TOOLS =../../Tools
OTHERS =  *.img *.rom *.com *.bin *.z80 cpm.sys zsys.sys Build.inc RomDisk.tmp font*.asm
include $(TOOLS)/Makefile.inc

ifeq ($(DIFFMAKE),1)
	DIFFBUILD := -d $(DIFFTO)/Source/HBIOS
endif

DIFFPATH = $(DIFFTO)/Binary


ROMSIZE=512

N8_std.rom: ROMSIZE=512

%.rom:
	bash Build.sh $(DIFFBUILD) $(shell echo $* | tr '_' ' ') $(ROMSIZE)

#ZETA2_std.rom:
#	bash Build.sh ZETA2 std 512

hbios_rom.bin:	hbios.asm build.inc
	$(TASM) -dROMBOOT hbios.asm hbios_rom.bin hbios_rom.lst

hbios_app.bin:	hbios.asm build.inc
	$(TASM) -dAPPBOOT hbios.asm hbios_app.bin hbios_app.lst

hbios_img.bin:	hbios.asm build.inc
	$(TASM) -dIMGBOOT hbios.asm hbios_img.bin hbios_img.lst

romldr.bin:	build.inc
dbgmon.bin:	build.inc
nascom.bin:	build.inc
eastaegg.bin:	build.inc

dumps:
	for i in $(MOREDIFF) ; do \
		hexdump -C $$i >$$i.dump ; \
	done
