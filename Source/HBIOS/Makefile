ifndef ROM_CONFIG
	ROM_CONFIG=std
endif

ifdef ROM_PLATFORM
	OBJECTS = ${ROM_PLATFORM}_${ROM_CONFIG}.rom ${ROM_PLATFORM}_${ROM_CONFIG}.com
else
	OBJECTS += DYNO_std.rom DYNO_std.com
	OBJECTS += EZZ80_std.rom EZZ80_std.com
	OBJECTS += MK4_std.rom MK4_std.com
	OBJECTS += N8_std.rom N8_std.com
	OBJECTS += RCZ180_ext.rom RCZ180_ext.com
	OBJECTS += RCZ180_nat.rom RCZ180_nat.com
	OBJECTS += RCZ80_kio.rom RCZ80_kio.com
	OBJECTS += RCZ80_mt.rom RCZ80_mt.com
	OBJECTS += RCZ80_duart.rom RCZ80_duart.com
	OBJECTS += RCZ80_std.rom RCZ80_std.com
	OBJECTS += SBC_simh.rom SBC_simh.com
	OBJECTS += SBC_std.rom SBC_std.com
	OBJECTS += SCZ180_126.rom SCZ180_126.com
	OBJECTS += SCZ180_130.rom SCZ180_130.com
	OBJECTS += SCZ180_131.rom SCZ180_131.com
	OBJECTS += UNA_std.rom
	OBJECTS += ZETA_std.rom ZETA_std.com
	OBJECTS += ZETA2_std.rom ZETA2_std.com
endif

MOREDIFF = camel80.bin game.bin hbios_rom.bin nascom.bin prefix.bin usrrom.bin \
	dbgmon.bin hbios_app.bin imgpad0.bin osimg1.bin romldr.bin \
	eastaegg.bin hbios_img.bin imgpad.bin osimg.bin tastybasic.bin \
	game.bin usrrom.bin

SUBDIRS =
DEST = ../../Binary
TOOLS =../../Tools
OTHERS =  *.img *.rom *.com *.bin *.z80 cpm.sys zsys.sys Build.inc RomDisk.tmp font*.asm *.dat
include $(TOOLS)/Makefile.inc

ifeq ($(DIFFMAKE),1)
	DIFFBUILD := -d $(DIFFTO)/Source/HBIOS
endif

DIFFPATH = $(DIFFTO)/Binary


ROMSIZE=512

N8_std.rom: ROMSIZE=512

%.rom:
	bash Build.sh $(DIFFBUILD) $(shell echo $* | sed 's/_/ /') $(ROMSIZE)

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
