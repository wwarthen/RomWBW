HD1KZZRCCPREFIX = hd1k_zzrcc_prefix.dat
HD1KZZRCCCOMBOIMG = hd1k_zzrcc_combo.img
HD1KZZRCCRAMPREFIX = hd1k_zzrcc_ram_prefix.dat
HD1KZZRCCRAMCOMBOIMG = hd1k_zzrcc_ram_combo.img
ZZRCCROM = ../../Binary/RCZ280_zzrcc.rom
ZZRCCRAMROM = ../../Binary/RCZ280_zzrcc_ram.rom
HD1KIMGS = ../../Binary/hd1k_cpm22.img ../../Binary/hd1k_zsdos.img ../../Binary/hd1k_nzcom.img \
	../../Binary/hd1k_cpm3.img ../../Binary/hd1k_zpm3.img ../../Binary/hd1k_ws4.img

OBJECTS :=

ifneq ($(wildcard $(ZZRCCROM)),)
	OBJECTS += $(HD1KZZRCCPREFIX) $(HD1KZZRCCCOMBOIMG)
endif

ifneq ($(wildcard $(ZZRCCRAMROM)),)
	OBJECTS += $(HD1KZZRCCRAMPREFIX) $(HD1KZZRCCRAMCOMBOIMG)
endif

DEST=../../Binary

TOOLS = ../../Tools

include $(TOOLS)/Makefile.inc

DIFFPATH = $(DIFFTO)/Binary

$(HD1KZZRCCPREFIX):
	srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x0 0x200 zzrcc_cfldr.bin -binary -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x1B8 0x200 zzrcc_ptbl.bin -binary -offset 0x1B8 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x1F000 0x20000 zzrcc_mon.bin -binary -offset 0x1F000 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x24000 0xA4000 $(ZZRCCROM) -binary -offset 0x24000 -o temp.dat -binary
	mv temp.dat $@

$(HD1KZZRCCRAMPREFIX):
	srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x0 0x200 zzrcc_cfldr.bin -binary -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x1B8 0x200 zzrcc_ptbl.bin -binary -offset 0x1B8 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x1F000 0x20000 zzrcc_mon.bin -binary -offset 0x1F000 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x24000 0xA4000 $(ZZRCCRAMROM) -binary -offset 0x24000 -o temp.dat -binary
	mv temp.dat $@

$(HD1KZZRCCCOMBOIMG): $(HD1KZZRCCPREFIX) $(HD1KIMGS)
	cat $^ > $@

$(HD1KZZRCCRAMCOMBOIMG): $(HD1KZZRCCRAMPREFIX) $(HD1KIMGS)
	cat $^ > $@
