HD1KZZRCPREFIX = hd1k_zzrc_prefix.dat
HD1KZZRCCOMBOIMG = hd1k_zzrc_combo.img
HD1KZZRCRAMPREFIX = hd1k_zzrc_ram_prefix.dat
HD1KZZRCRAMCOMBOIMG = hd1k_zzrc_ram_combo.img
ZZRCROM = ../../Binary/RCZ280_zzrc.rom
ZZRCRAMROM = ../../Binary/RCZ280_zzrc_ram.rom
HD1KIMGS = ../../Binary/hd1k_cpm22.img ../../Binary/hd1k_zsdos.img ../../Binary/hd1k_nzcom.img \
	../../Binary/hd1k_cpm3.img ../../Binary/hd1k_zpm3.img ../../Binary/hd1k_ws4.img

OBJECTS :=

ifneq ($(wildcard $(ZZRCROM)),)
	OBJECTS += $(HD1KZZRCPREFIX) $(HD1KZZRCCOMBOIMG)
endif

ifneq ($(wildcard $(ZZRCRAMROM)),)
	OBJECTS += $(HD1KZZRCRAMPREFIX) $(HD1KZZRCRAMCOMBOIMG)
endif

DEST=../../Binary

TOOLS = ../../Tools

include $(TOOLS)/Makefile.inc

DIFFPATH = $(DIFFTO)/Binary

$(HD1KZZRCPREFIX):
	srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x0 0x100 zzrc_cfldr.bin -binary -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x100 0x200 zzrc_ptbl.bin -binary -offset 0x100 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x1F000 0x20000 zzrc_mon.bin -binary -offset 0x1F000 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x24000 0xA4000 $(ZZRCROM) -binary -offset 0x24000 -o temp.dat -binary
	mv temp.dat $@

$(HD1KZZRCRAMPREFIX):
	srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x0 0x100 zzrc_cfldr.bin -binary -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x100 0x200 zzrc_ptbl.bin -binary -offset 0x100 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x1F000 0x20000 zzrc_mon.bin -binary -offset 0x1F000 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x24000 0xA4000 $(ZZRCRAMROM) -binary -offset 0x24000 -o temp.dat -binary
	mv temp.dat $@

$(HD1KZZRCCOMBOIMG): $(HD1KZZRCPREFIX) $(HD1KIMGS)
	cat $^ > $@

$(HD1KZZRCRAMCOMBOIMG): $(HD1KZZRCRAMPREFIX) $(HD1KIMGS)
	cat $^ > $@
