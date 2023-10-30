HD1KZ1RCCPREFIX = hd1k_z1rcc_prefix.dat
HD1KZ1RCCCOMBOIMG = hd1k_z1rcc_combo.img
Z1RCCROM = ../../Binary/RCZ180_z1rcc.rom
HD1KIMGS = ../../Binary/hd1k_cpm22.img ../../Binary/hd1k_zsdos.img ../../Binary/hd1k_nzcom.img \
	../../Binary/hd1k_cpm3.img ../../Binary/hd1k_zpm3.img ../../Binary/hd1k_ws4.img

OBJECTS :=

ifneq ($(wildcard $(Z1RCCROM)),)
	OBJECTS += $(HD1KZ1RCCPREFIX) $(HD1KZ1RCCCOMBOIMG)
endif

DEST=../../Binary

TOOLS = ../../Tools

include $(TOOLS)/Makefile.inc

DIFFPATH = $(DIFFTO)/Binary

$(HD1KZ1RCCPREFIX):
	srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x0 0x200 z1rcc_cfldr.bin -binary -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x1B8 0x200 z1rcc_ptbl.bin -binary -offset 0x1B8 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x1F000 0x20000 z1rcc_mon.bin -binary -offset 0x1F000 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x24000 0xA4000 $(Z1RCCROM) -binary -offset 0x24000 -o temp.dat -binary
	mv temp.dat $@

$(HD1KZ1RCCCOMBOIMG): $(HD1KZ1RCCPREFIX) $(HD1KIMGS)
	cat $^ > $@
