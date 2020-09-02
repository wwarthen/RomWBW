HD1024ZRCPREFIX = hd1024_zrc_prefix.dat
ZRCROM = ../../Binary/RCZ80_zrc.rom

OBJECTS :=

ifneq ($(wildcard $(ZRCROM)),)
	OBJECTS += $(HD1024ZRCPREFIX)
endif

DEST=../../Binary

TOOLS = ../../Tools

include $(TOOLS)/Makefile.inc

DIFFPATH = $(DIFFTO)/Binary

$(HD1024ZRCPREFIX):
	cat zrc_cfldr.bin zrc_ptbl.bin zrc_fill_1.bin zrc_mon.bin zrc_fill_2.bin $(ZRCROM) zrc_fill_3.bin >$@