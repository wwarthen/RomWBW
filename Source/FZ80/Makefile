HD1KFZ80PREFIX = hd1k_fz80_prefix.dat
HD1KFZ80COMBOIMG = hd1k_fz80_combo.img
FZ80ROM = ../../Binary/FZ80_std.rom
HD1KIMGS = ../../Binary/hd1k_cpm22.img ../../Binary/hd1k_zsdos.img ../../Binary/hd1k_nzcom.img \
	../../Binary/hd1k_cpm3.img ../../Binary/hd1k_zpm3.img ../../Binary/hd1k_ws4.img

OBJECTS := $(HD1KFZ80PREFIX) $(HD1KFZ80COMBOIMG)

DEST=../../Binary

TOOLS = ../../Tools

include $(TOOLS)/Makefile.inc

DIFFPATH = $(DIFFTO)/Binary

$(HD1KFZ80PREFIX):
	srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x1B8 0x200 fz80_ptbl.bin -binary -offset 0x1B8 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x80000 0xE0000 $(FZ80ROM) -binary -offset 0x80000 -o temp.dat -binary
	mv temp.dat $@

$(HD1KFZ80COMBOIMG): $(HD1KFZ80PREFIX) $(HD1KIMGS)
	cat $^ > $@
