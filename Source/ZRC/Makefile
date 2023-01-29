HD1KZRCPREFIX = hd1k_zrc_prefix.dat
HD1KZRCCOMBOIMG = hd1k_zrc_combo.img
HD1KZRCRAMPREFIX = hd1k_zrc_ram_prefix.dat
HD1KZRCRAMCOMBOIMG = hd1k_zrc_ram_combo.img
ZRCROM = ../../Binary/RCZ80_zrc.rom
ZRCRAMROM = ../../Binary/RCZ80_zrc_ram.rom
HD1KIMGS = ../../Binary/hd1k_cpm22.img ../../Binary/hd1k_zsdos.img ../../Binary/hd1k_nzcom.img \
	../../Binary/hd1k_cpm3.img ../../Binary/hd1k_zpm3.img ../../Binary/hd1k_ws4.img

OBJECTS :=

ifneq ($(wildcard $(ZRCROM)),)
	OBJECTS += $(HD1KZRCPREFIX) $(HD1KZRCCOMBOIMG)
endif

ifneq ($(wildcard $(ZRCRAMROM)),)
	OBJECTS += $(HD1KZRCRAMPREFIX) $(HD1KZRCRAMCOMBOIMG)
endif

DEST=../../Binary

TOOLS = ../../Tools

include $(TOOLS)/Makefile.inc

DIFFPATH = $(DIFFTO)/Binary

$(HD1KZRCPREFIX):
	srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x0 0x100 zrc_cfldr.bin -binary -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x100 0x200 zrc_ptbl.bin -binary -offset 0x100 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x1F000 0x20000 zrc_mon.bin -binary -offset 0x1F000 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x24000 0xA4000 $(ZRCROM) -binary -offset 0x24000 -o temp.dat -binary
	mv temp.dat $@

$(HD1KZRCRAMPREFIX):
	srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x0 0x100 zrc_cfldr.bin -binary -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x100 0x200 zrc_ptbl.bin -binary -offset 0x100 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x1F000 0x20000 zrc_mon.bin -binary -offset 0x1F000 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x24000 0xA4000 $(ZRCRAMROM) -binary -offset 0x24000 -o temp.dat -binary
	mv temp.dat $@

$(HD1KZRCCOMBOIMG): $(HD1KZRCPREFIX) $(HD1KIMGS)
	cat $^ > $@

$(HD1KZRCRAMCOMBOIMG): $(HD1KZRCRAMPREFIX) $(HD1KIMGS)
	cat $^ > $@
