HD1KZRC512PREFIX = hd1k_zrc512_prefix.dat
HD1KZRC512COMBOIMG = hd1k_zrc512_combo.img
ZRC512ROM = ../../Binary/RCZ80_zrc512.rom
HD1KIMGS = ../../Binary/hd1k_cpm22.img ../../Binary/hd1k_zsdos.img ../../Binary/hd1k_nzcom.img \
	../../Binary/hd1k_cpm3.img ../../Binary/hd1k_zpm3.img ../../Binary/hd1k_ws4.img

OBJECTS :=

ifneq ($(wildcard $(ZRC512ROM)),)
	OBJECTS += $(HD1KZRC512PREFIX) $(HD1KZRC512COMBOIMG)
endif

DEST=../../Binary

TOOLS = ../../Tools

include $(TOOLS)/Makefile.inc

DIFFPATH = $(DIFFTO)/Binary

$(HD1KZRC512PREFIX):
	srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x0 0x200 zrc512_cfldr.bin -binary -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x1B8 0x200 zrc512_ptbl.bin -binary -offset 0x1B8 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x1F000 0x20000 zrc512_mon.bin -binary -offset 0x1F000 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x24000 0xA4000 $(ZRC512ROM) -binary -offset 0x24000 -o temp.dat -binary
	mv temp.dat $@

$(HD1KZRC512COMBOIMG): $(HD1KZRC512PREFIX) $(HD1KIMGS)
	cat $^ > $@
