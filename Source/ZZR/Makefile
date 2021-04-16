HD1024ZZRPREFIX = hd1024_zzr_prefix.dat
HD1024ZZZROMBOIMG = hd1024_zzr_combo.img
ZZRROM = ../../Binary/RCZ280_nat_zzr.rom
ZZRLDRROM = RCZ280_nat_zzr_ldr.rom
ZZRROMHEX = RCZ280_nat_zzr.hex
HD1024IMGS = ../../Binary/hd1024_cpm22.img ../../Binary/hd1024_zsdos.img ../../Binary/hd1024_nzcom.img \
	../../Binary/hd1024_cpm3.img ../../Binary/hd1024_zpm3.img ../../Binary/hd1024_ws4.img


OBJECTS :=

ifneq ($(wildcard $(ZZRROM)),)
#	OBJECTS +=  $(ZZRROMHEX) $(ZZRLDRROM) $(HD1024ZZRPREFIX) $(HD1024ZZZROMBOIMG)
	OBJECTS +=  $(HD1024ZZRPREFIX) $(HD1024ZZZROMBOIMG)
endif

DEST=../../Binary

TOOLS = ../../Tools

include $(TOOLS)/Makefile.inc

DIFFPATH = $(DIFFTO)/Binary

$(HD1024ZZRPREFIX):
#	cat zzr_cfldr.bin zzr_ptbl.bin zzr_fill_1.bin zzr_mon.bin zzr_fill_2.bin $(ZZRLDRROM) zzr_fill_3.bin >$@
	cat zzr_cfldr.bin zzr_ptbl.bin zzr_fill_1.bin zzr_mon.bin zzr_fill_2.bin $(ZZRROM) zzr_fill_3.bin >$@

$(HD1024ZZZROMBOIMG): $(HD1024ZZRPREFIX) $(HD1024IMGS)
	cat $^ > $@

$(ZZRROMHEX): $(ZZRROM)
	srec_cat $(ZZRROM) -Binary -Exclude 0x5000 0x7000 zzr_romldr.hex -Intel -Output $(ZZRROMHEX) -Intel

$(ZZRLDRROM): $(ZZRROMHEX)
	srec_cat $(ZZRROMHEX) -Intel -Output $(ZZRLDRROM) -Binary
