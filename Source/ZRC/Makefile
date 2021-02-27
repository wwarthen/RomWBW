HD1024ZRCPREFIX = hd1024_zrc_prefix.dat
HD1024ZRCCOMBOIMG = hd1024_zrc_combo.img
ZRCROM = ../../Binary/RCZ80_zrc.rom
HD1024IMGS = ../../Binary/hd1024_cpm22.img ../../Binary/hd1024_zsdos.img ../../Binary/hd1024_nzcom.img \
	../../Binary/hd1024_cpm3.img ../../Binary/hd1024_zpm3.img ../../Binary/hd1024_ws4.img

OBJECTS :=

ifneq ($(wildcard $(ZRCROM)),)
	OBJECTS += $(HD1024ZRCPREFIX) $(HD1024ZRCCOMBOIMG)
endif

DEST=../../Binary

TOOLS = ../../Tools

include $(TOOLS)/Makefile.inc

DIFFPATH = $(DIFFTO)/Binary

$(HD1024ZRCPREFIX):
	cat zrc_cfldr.bin zrc_ptbl.bin zrc_fill_1.bin zrc_mon.bin zrc_fill_2.bin $(ZRCROM) zrc_fill_3.bin >$@

$(HD1024ZRCCOMBOIMG): $(HD1024ZRCPREFIX) $(HD1024IMGS)
	cat $^ > $@