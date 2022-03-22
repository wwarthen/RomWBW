HD1024ZRCPREFIX = hd1024_zrc_prefix.dat
HD1024ZRCCOMBOIMG = hd1024_zrc_combo.img
HD1024ZRCRAMPREFIX = hd1024_zrc_ram_prefix.dat
HD1024ZRCRAMCOMBOIMG = hd1024_zrc_ram_combo.img
ZRCROM = ../../Binary/RCZ80_zrc.rom
ZRCRAMROM = ../../Binary/RCZ80_zrc_ram.rom
HD1024IMGS = ../../Binary/hd1024_cpm22.img ../../Binary/hd1024_zsdos.img ../../Binary/hd1024_nzcom.img \
	../../Binary/hd1024_cpm3.img ../../Binary/hd1024_zpm3.img ../../Binary/hd1024_ws4.img

OBJECTS :=

ifneq ($(wildcard $(ZRCROM)),)
	OBJECTS += $(HD1024ZRCPREFIX) $(HD1024ZRCCOMBOIMG)
endif

ifneq ($(wildcard $(ZRCRAMROM)),)
	OBJECTS += $(HD1024ZRCRAMPREFIX) $(HD1024ZRCRAMCOMBOIMG)
endif

DEST=../../Binary

TOOLS = ../../Tools

include $(TOOLS)/Makefile.inc

DIFFPATH = $(DIFFTO)/Binary

$(HD1024ZRCPREFIX):
	srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x0 0x100 zrc_cfldr.bin -binary -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x100 0x200 zrc_ptbl.bin -binary -offset 0x100 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x1F000 0x20000 zrc_mon.bin -binary -offset 0x1F000 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x24000 0xA4000 $(ZRCROM) -binary -offset 0x24000 -o temp.dat -binary
	mv temp.dat $@

$(HD1024ZRCRAMPREFIX):
	srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x0 0x100 zrc_cfldr.bin -binary -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x100 0x200 zrc_ptbl.bin -binary -offset 0x100 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x1F000 0x20000 zrc_mon.bin -binary -offset 0x1F000 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x24000 0xA4000 $(ZRCRAMROM) -binary -offset 0x24000 -o temp.dat -binary
	mv temp.dat $@

$(HD1024ZRCCOMBOIMG): $(HD1024ZRCPREFIX) $(HD1024IMGS)
	cat $^ > $@

$(HD1024ZRCRAMCOMBOIMG): $(HD1024ZRCRAMPREFIX) $(HD1024IMGS)
	cat $^ > $@
