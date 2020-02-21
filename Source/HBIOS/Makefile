OBJECTS = ZETA2_std.rom
MOREDIFF = camel80.bin game.bin hbios_rom.bin nascom.bin prefix.bin usrrom.bin \
	dbgmon.bin hbios_app.bin imgpad0.bin osimg1.bin romldr.bin \
	eastaegg.bin hbios_img.bin imgpad.bin osimg.bin tastybasic.bin \
	game.bin usrrom.bin

SUBDIRS = 
DEST = ../../Binary
TOOLS =../../Tools
OTHERS =  *.bin *.z80 cpm.sys zsys.sys Build.inc
include $(TOOLS)/Makefile.inc
DIFFPATH = $(DIFFTO)/Binary

ZETA2_std.rom:
	bash Build.sh ZETA2 std 512

hbios_rom.bin:	hbios.asm
	$(TASM) -dROMBOOT hbios.asm hbios_rom.bin

hbios_app.bin:	hbios.asm
	$(TASM) -dAPPBOOT hbios.asm hbios_app.bin

hbios_img.bin:	hbios.asm
	$(TASM) -dIMGBOOT hbios.asm hbios_img.bin

