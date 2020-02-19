OBJECTS = ZETA2_std.rom
SUBDIRS = 
DEST = ../../Binary/Apps
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

