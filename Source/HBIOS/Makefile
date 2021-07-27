ifndef ROM_CONFIG
	ROM_CONFIG=std
endif

ifdef ROM_PLATFORM
	OBJECTS = ${ROM_PLATFORM}_${ROM_CONFIG}.rom ${ROM_PLATFORM}_${ROM_CONFIG}.com ${ROM_PLATFORM}_${ROM_CONFIG}.upd
else
	OBJECTS += DYNO_std.rom DYNO_std.com DYNO_std.upd
	OBJECTS += EZZ80_std.rom EZZ80_std.com EZZ80_std.upd
	OBJECTS += EZZ80_tz80.rom EZZ80_tz80.com EZZ80_tz80.upd
	OBJECTS += MK4_std.rom MK4_std.com MK4_std.upd
	OBJECTS += N8_std.rom N8_std.com N8_std.upd
	OBJECTS += RCZ180_ext.rom RCZ180_ext.com RCZ180_ext.upd
	OBJECTS += RCZ180_nat.rom RCZ180_nat.com RCZ180_nat.upd
	OBJECTS += RCZ280_ext.rom RCZ280_ext.com RCZ280_ext.upd
	OBJECTS += RCZ280_nat.rom RCZ280_nat.com RCZ280_nat.upd
	OBJECTS += RCZ280_nat_zz.rom RCZ280_nat_zz.com RCZ280_nat_zz.upd
	OBJECTS += RCZ280_nat_zzr.rom RCZ280_nat_zzr.com RCZ280_nat_zzr.upd
	OBJECTS += RCZ80_kio.rom RCZ80_kio.com RCZ80_kio.upd
	OBJECTS += RCZ80_mt.rom RCZ80_mt.com RCZ80_mt.upd
	OBJECTS += RCZ80_duart.rom RCZ80_duart.com RCZ80_duart.upd
	OBJECTS += RCZ80_std.rom RCZ80_std.com RCZ80_std.upd
	OBJECTS += RCZ80_skz.rom RCZ80_skz.com RCZ80_skz.upd
	OBJECTS += RCZ80_zrc.rom RCZ80_zrc.com RCZ80_zrc.upd
	OBJECTS += SBC_std.rom SBC_std.com SBC_std.upd
	OBJECTS += SBC_simh.rom SBC_simh.com SBC_simh.upd
	OBJECTS += MBC_std.rom MBC_std.com MBC_std.upd
	OBJECTS += SCZ180_126.rom SCZ180_126.com SCZ180_126.upd
	OBJECTS += SCZ180_130.rom SCZ180_130.com SCZ180_130.upd
	OBJECTS += SCZ180_131.rom SCZ180_131.com SCZ180_131.upd
	OBJECTS += SCZ180_140.rom SCZ180_140.com SCZ180_140.upd
	OBJECTS += UNA_std.rom
	OBJECTS += ZETA_std.rom ZETA_std.com ZETA_std.upd
	OBJECTS += ZETA2_std.rom ZETA2_std.com ZETA2_std.upd
endif

MOREDIFF = camel80.bin game.bin hbios_rom.bin nascom.bin prefix.bin usrrom.bin \
	dbgmon.bin hbios_app.bin imgpad2.bin osimg1.bin osimg2.bin romldr.bin \
	eastaegg.bin hbios_img.bin osimg.bin tastybasic.bin \
	game.bin updater.bin usrrom.bin

SUBDIRS =
DEST = ../../Binary
TOOLS =../../Tools
OTHERS =  *.img *.rom *.com *.bin *.z80 cpm.sys zsys.sys Build.inc font*.asm *.dat
include $(TOOLS)/Makefile.inc

FONTS := font8x11c.asm font8x11u.asm font8x16c.asm font8x16u.asm font8x8c.asm font8x8u.asm

ifneq ($(findstring $(platform), N8 MK4 RCZ180 SCZ180 DYNO),)
	TASM=$(BINDIR)/uz80as -t hd64180
endif

ifneq ($(findstring $(platform), RCZ280),)
	TASM=$(BINDIR)/uz80as -t z280
endif

ifeq ($(DIFFMAKE),1)
	DIFFBUILD := -d $(DIFFTO)/Source/HBIOS
endif

DIFFPATH = $(DIFFTO)/Binary

ROMSIZE=512

N8_std.rom: ROMSIZE=512
RCZ280_nat_zzr.rom: ROMSIZE=256

%.rom %.upd %.com:
	chmod +x Build.sh
	bash Build.sh $(DIFFBUILD) $(shell echo $* | sed 's/_/ /') $(ROMSIZE)
	
prereq: $(FONTS) camel80.bin

font%.asm:
	cp ../Fonts/$@ .

camel80.bin:
	cp ../Forth/$@ .
	
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
updater.bin:	build.inc

dumps:
	for i in $(MOREDIFF) ; do \
		hexdump -C $$i >$$i.dump ; \
	done
