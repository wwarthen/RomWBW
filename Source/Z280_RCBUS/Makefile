DEST=../../Binary

HD1KIMGS = $(DEST)/hd1k_cpm22.img $(DEST)/hd1k_zsdos.img $(DEST)/hd1k_nzcom.img \
	$(DEST)/hd1k_cpm3.img $(DEST)/hd1k_zpm3.img $(DEST)/hd1k_wp.img

ROMS := $(wildcard $(DEST)/RCZ280_rcbus_*.rom)
ROMS := $(patsubst $(DEST)/%.rom,%,$(ROMS))

OBJECTS := $(patsubst %,%_hd1k_prefix.dat,$(ROMS))
OBJECTS += $(patsubst %,%_hd1k_combo.img,$(ROMS))

TOOLS = ../../Tools

include $(TOOLS)/Makefile.inc

DIFFPATH = $(DIFFTO)/Binary

%_hd1k_prefix.dat: $(DEST)/%.rom
	srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x1B8 0x200 ptbl.bin -binary -offset 0x1B8 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x24000 0xA4000 $< -binary -offset 0x24000 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x240EF 0x24100 -generate 0x240EF 0x24100 -repeat-data 0xED 0xBF 0xED 0xB7 0xCB 0x7C 0x20 0xFA 0x2E 0x00 0x0E 0x08 0xED 0x6E 0xC3 0x00 0x00 -o temp.dat -binary
	mv temp.dat $@

%_hd1k_combo.img: %_hd1k_prefix.dat  $(HD1KIMGS)
	cat $^ > $@
