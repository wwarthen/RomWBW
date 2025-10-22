
MOREDIFF = game.bin hbios_rom.bin nascom.bin usrrom.bin \
	dbgmon.bin hbios_app.bin rom2.bin rom3.bin romldr.bin \
	eastaegg.bin hbios_img.bin rom1.bin game.bin updater.bin usrrom.bin

DEST = ../../Binary
TOOLS =../../Tools
OTHERS =  *.img *.rom *.com *.upd *.bin *.hex cpm.sys zsys.sys Build.inc font*.asm *.dat hbios_env.sh

# DIFFMAKE = 1

# DIFFPATH = $(DIFFTO)/Binary

ifeq ($(DIFFMAKE),1)
	DIFFBUILD := -d $(DIFFTO)/Source/HBIOS
endif

ifeq ($(OBJECTS),)
start:
	@chmod +x Build.sh
	bash Build.sh $(DIFFBUILD)
endif

include $(TOOLS)/Makefile.inc

FONTS := font6x8c.asm font6x8u.asm font8x8c.asm font8x8u.asm \
	font8x11c.asm font8x11u.asm font8x16c.asm font8x16u.asm

ifeq ($(CPUFAM),2)
	TASM=$(BINDIR)/uz80as -t hd64180
else ifeq ($(CPUFAM),3)
	TASM=$(BINDIR)/uz80as -t z280
endif

DEPS=prereq dbgmon.bin romldr.bin nascom.bin tastybasic.bin invntdev.bin invntslc.bin game.bin eastaegg.bin updater.bin sysconf.bin sysconf.com usrrom.bin romfonts.bin

ifeq ($(ROM_PLATFORM),UNA)
	ROMDEPS=romldr.bin dbgmon.bin
	BIOS=una
else
	ROMDEPS=hbios_rom.bin hbios_app.bin hbios_img.bin
	BIOS=wbw
endif

ifeq ($(ROM_PLATFORM),SZ180)
	HWMON=sz180mon.bin
else
	HWMON=hwmon.bin
endif

ifeq ($(ROM_PLATFORM),DUO)
	NETBOOT=netboot-duo.mod
else
	NETBOOT=netboot-mt.mod
endif

DEPS += $(HWMON) $(NETBOOT)

ROMNAME=${ROM_PLATFORM}_${ROM_CONFIG}

# $(info DEPS=$(DEPS))
# $(info ROM_PLATFORM=$(ROM_PLATFORM))
# $(info ROM_CONFIG=$(ROM_CONFIG))
# $(info ROMSIZE=$(ROMSIZE))
# $(info RAMSIZE=$(RAMSIZE))
# $(info ROMNAME=$(ROMNAME))
# $(info CPUFAM=$(CPUFAM))
# $(info TASM=$(TASM))

$(OBJECTS) : $(ROMDEPS)
	@cat romldr.bin dbgmon.bin ../ZSDOS/zsys_$(BIOS).bin ../CPM22/cpm_$(BIOS).bin >rom1.bin
	cat romldr.bin dbgmon.bin ../ZSDOS/zsys_$(BIOS).bin >appboot.bin
	if [ $(ROM_PLATFORM) != UNA ] ; then \
		cat camel80.bin nascom.bin tastybasic.bin game.bin eastaegg.bin $(NETBOOT) updater.bin sysconf.bin usrrom.bin >rom2.bin ; \
		cat $(HWMON) invntdev.bin invntslc.bin romfonts.bin >rom3.bin ; \
		for f in hbios_rom.bin rom1.bin rom2.bin rom3.bin ; do \
			srec_cat $$f -Binary -Crop 0 0x7FFF -Checksum_Negative_Big_Endian 0x7FFF 1 1 -o $$f -Binary ; \
		done \
	fi
	if [ $(ROM_PLATFORM) = UNA ] ; then \
		cp rom1.bin $(DEST)/UNA_WBW_SYS.bin ; \
		cp ../RomDsk/rom$(ROMDISKSIZE)_una.dat $(DEST)/UNA_WBW_ROM$(ROMDISKSIZE).bin ; \
		cat ../UBIOS/UNA-BIOS.BIN rom1.bin ../UBIOS/FSFAT.BIN ../RomDsk/rom$(ROMDISKSIZE)_una.dat >$(ROMNAME).rom ; \
	else \
		if [ $(ROMSIZE) -gt 0 ] ; then \
			cat hbios_rom.bin rom1.bin rom2.bin rom3.bin ../RomDsk/rom$(ROMDISKSIZE)_wbw.dat >$(ROMNAME).rom ; \
			cat hbios_rom.bin rom1.bin rom2.bin rom3.bin >$(ROMNAME).upd ; \
			cat hbios_app.bin appboot.bin > $(ROMNAME).com ; \
		else \
			cat hbios_rom.bin rom1.bin rom2.bin rom3.bin ../RomDsk/rom$(RAMDISKSIZE)_wbw.dat >$(ROMNAME).rom ; \
			cat hbios_rom.bin rom1.bin rom2.bin rom3.bin >$(ROMNAME).upd ; \
			cat hbios_app.bin appboot.bin > $(ROMNAME).com ; \
		fi \
	fi

prereq: $(FONTS) camel80.bin tastybasic.bin

font%.asm:
	cp ../Fonts/$@ .

camel80.bin:
	cp ../Forth/$@ .

sysconf.bin:
	@$(TASM) -dROMWBW sysconf.asm sysconf.bin sysconf_bin.lst

sysconf.com:
	@$(TASM) -dCPM sysconf.asm sysconf.com sysconf_com.lst
	cp $@ $(DEST)/Apps

sz180mon.bin:
	$(ZXCC) $(CPM)/SLR180 -sz180mon/FH
	$(ZXCC) $(CPM)/MLOAD25 -sz180mon.bin=sz180mon

tastybasic.bin:
	cp ../TastyBasic/src/$@ .

hbios_rom.bin:	hbios.asm build.inc  $(DEPS)
	@$(TASM) -dROMBOOT hbios.asm hbios_rom.bin hbios_rom.lst

hbios_app.bin:	hbios.asm build.inc  $(DEPS)
	@$(TASM) -dAPPBOOT hbios.asm hbios_app.bin hbios_app.lst

hbios_img.bin:	hbios.asm build.inc  $(DEPS)
	@$(TASM) -dIMGBOOT hbios.asm hbios_img.bin hbios_img.lst

hbios_env.com:	hbios_env.asm build.inc
	@$(TASM) -dBASH hbios_env.asm hbios_env.com hbios_env.lst

hbios_env.sh: hbios_env.com
	@$(ZXCC) hbios_env.com >hbios_env.sh

romldr.bin:	build.inc
dbgmon.bin:	build.inc
nascom.bin:	build.inc
invntdev.bin:	build.inc
invntslc.bin:	build.inc
eastaegg.bin:	build.inc
updater.bin:	build.inc
romfonts.bin:	build.inc
hwmon.bin:	build.inc
sz180mon.bin:	build.inc

dumps:
	for i in $(MOREDIFF) ; do \
		hexdump -C $$i >$$i.dump ; \
	done
