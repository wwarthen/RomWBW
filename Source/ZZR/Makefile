HD1KZZRPREFIX = hd1k_zzr_prefix.dat
HD1KZZZROMBOIMG = hd1k_zzr_combo.img
ZZRROM = ../../Binary/RCZ280_nat_zzr.rom
ZZRROMHEX = RCZ280_nat_zzr.hex
HD1KIMGS = ../../Binary/hd1k_cpm22.img ../../Binary/hd1k_zsdos.img ../../Binary/hd1k_nzcom.img \
	../../Binary/hd1k_cpm3.img ../../Binary/hd1k_zpm3.img ../../Binary/hd1k_ws4.img
ZZRROMSIZE = 262144

OBJECTS :=

ifneq ($(wildcard $(ZZRROM)),)
	OBJECTS += $(ZZRROMHEX) $(HD1KZZRPREFIX) $(HD1KZZZROMBOIMG)
endif

DEST=../../Binary

TOOLS = ../../Tools

include $(TOOLS)/Makefile.inc

DIFFPATH = $(DIFFTO)/Binary

zzrromchk:
	[ `wc -c $(ZZRROM) | awk '{print $$1}'` = $(ZZRROMSIZE) ]
	
$(HD1KZZRPREFIX): zzrromchk
	cat zzr_cfldr.bin zzr_ptbl.bin zzr_fill_1.bin zzr_mon.bin zzr_fill_2.bin $(ZZRROM) zzr_fill_3.bin >$@

$(HD1KZZZROMBOIMG): zzrromchk $(HD1KZZRPREFIX) $(HD1KIMGS)
	cat $(HD1KZZRPREFIX) $(HD1KIMGS) > $@

$(ZZRROMHEX): zzrromchk $(ZZRROM)
	srec_cat $(ZZRROM) -Binary -Output $(ZZRROMHEX) -Intel -CRLF
