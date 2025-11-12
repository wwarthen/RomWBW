DEST=../../Binary
OTHERS=*.hex *.upd *.cmp

HD1KIMGS = $(DEST)/hd1k_cpm22.img $(DEST)/hd1k_zsdos.img $(DEST)/hd1k_nzcom.img \
	$(DEST)/hd1k_cpm3.img $(DEST)/hd1k_zpm3.img $(DEST)/hd1k_wp.img

ROMS := $(wildcard $(DEST)/RCZ80_ez512_*.upd)
ROMS := $(patsubst $(DEST)/%.upd,%,$(ROMS))

OBJECTS := $(patsubst %,%_hd1k_prefix.dat,$(ROMS))
OBJECTS += $(patsubst %,%_hd1k_combo.img,$(ROMS))
OBJECTS += $(patsubst %,%_64k.rom,$(ROMS))

TOOLS = ../../Tools

include $(TOOLS)/Makefile.inc

DIFFPATH = $(DIFFTO)/Binary

%_hd1k_prefix.dat: $(DEST)/%.rom
	srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x0 0x200 ez512_cfldr.bin -binary -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x1B8 0x200 ez512_ptbl.bin -binary -offset 0x1B8 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x1F000 0x20000 ez512_mon.bin -binary -offset 0x1F000 -o temp.dat -binary
	srec_cat temp.dat -binary -exclude 0x24000 0xA4000 $< -binary -offset 0x24000 -o temp.dat -binary
	mv temp.dat $@

%_hd1k_combo.img: %_hd1k_prefix.dat  $(HD1KIMGS)
	cat $^ > $@

# The following recipe produces a 64K ROM that can be used in the EaZy80-512.
# In order to fit in the required 64K, TastyBASIC and the Game components
# are removed from the ROM.  If the layout of the ROM components
# changes (see ..\Source\layout.inc), the address range that is carved
# out below may need to be adjusted.

%_64k.rom: $(DEST)/%.upd decomp.hex
	srec_cat $< -binary -exclude 0x13700 0x14A00 -fill 0xC9 0x13700 0x14A00 -o temp.upd -binary
	$(COMPRESS) temp.upd
	srec_cat decomp.hex -intel temp.upd.cmp -binary -offset 3 -o $@ -binary
