HD1024ZZRPREFIX = hd1024_zzr_prefix.dat
HD1024ZZZROMBOIMG = hd1024_zzr_combo.img
ZZRROM = ../../Binary/RCZ280_nat_zzr.rom
ZZRROMHEX = RCZ280_nat_zzr.hex
HD1024IMGS = ../../Binary/hd1024_cpm22.img ../../Binary/hd1024_zsdos.img ../../Binary/hd1024_nzcom.img \
	../../Binary/hd1024_cpm3.img ../../Binary/hd1024_zpm3.img ../../Binary/hd1024_ws4.img
ZZRROMSIZE = 262144

OBJECTS :=

ifneq ($(wildcard $(ZZRROM)),)
	OBJECTS += $(ZZRROMHEX) $(HD1024ZZRPREFIX) $(HD1024ZZZROMBOIMG)
endif

DEST=../../Binary

TOOLS = ../../Tools

include $(TOOLS)/Makefile.inc

DIFFPATH = $(DIFFTO)/Binary

zzrromchk:
	[ `wc -c $(ZZRROM) | awk '{print $$1}'` = $(ZZRROMSIZE) ]
	
$(HD1024ZZRPREFIX): zzrromchk
	cat zzr_cfldr.bin zzr_ptbl.bin zzr_fill_1.bin zzr_mon.bin zzr_fill_2.bin $(ZZRROM) zzr_fill_3.bin >$@

$(HD1024ZZZROMBOIMG): zzrromchk $(HD1024ZZRPREFIX) $(HD1024IMGS)
	cat $(HD1024ZZRPREFIX) $(HD1024IMGS) > $@

$(ZZRROMHEX): zzrromchk $(ZZRROM)
	srec_cat $(ZZRROM) -Binary -Output $(ZZRROMHEX) -Intel -CRLF
