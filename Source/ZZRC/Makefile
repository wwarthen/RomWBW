HD1KZZRCPREFIX = hd1k_zzrc_prefix.dat
HD1KZZRCCOMBOIMG = hd1k_zzrc_combo.img
ZZRCROM = ../../Binary/RCZ280_zzrc.rom
ZZRCROMHEX = RCZ280_zzrc.hex
HD1KIMGS = ../../Binary/hd1k_cpm22.img ../../Binary/hd1k_zsdos.img ../../Binary/hd1k_nzcom.img \
	../../Binary/hd1k_cpm3.img ../../Binary/hd1k_zpm3.img ../../Binary/hd1k_ws4.img
ZZRCROMSIZE = 262144

OBJECTS :=

ifneq ($(wildcard $(ZZRCROM)),)
	OBJECTS += $(ZZRCROMHEX) $(HD1KZZRCPREFIX) $(HD1KZZRCCOMBOIMG)
endif

DEST=../../Binary

TOOLS = ../../Tools

include $(TOOLS)/Makefile.inc

DIFFPATH = $(DIFFTO)/Binary

zzrcromchk:
	[ `wc -c $(ZZRCROM) | awk '{print $$1}'` = $(ZZRCROMSIZE) ]
	
$(HD1KZZRCPREFIX): zzrcromchk
	cat zzrc_cfldr.bin zzrc_ptbl.bin zzrc_fill_1.bin zzrc_mon.bin zzrc_fill_2.bin $(ZZRCROM) zzrc_fill_3.bin >$@

$(HD1KZZRCCOMBOIMG): zzrcromchk $(HD1KZZRCPREFIX) $(HD1KIMGS)
	cat $(HD1KZZRCPREFIX) $(HD1KIMGS) > $@

$(ZZRCROMHEX): zzrcromchk $(ZZRCROM)
	srec_cat $(ZZRCROM) -Binary -Output $(ZZRCROMHEX) -Intel -CRLF
