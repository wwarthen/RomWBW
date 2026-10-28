DIST_ROMS := \
	SBC_std \
	SBC_simh_std \
	MBC_std \
	ZETA_std \
	ZETA2_std \
	N8_std \
	N8PC_std \
	MK4_std \
	RC2014_std \
	RCEZ80_std \
	RCZ80_std \
	RCZ80_kio_std \
	EZZ80_easy_std \
	EZZ80_tiny_std \
	RCZ80_skz_std \
	RCZ80_zrc_std \
	RCZ80_zrc512_std \
	RCZ80_ez512_std \
	RCZ80_k80w_std \
	RCZ180_ext_std \
	RCZ180_nat_std \
	RCZ180_z1rcc_std \
	RCZ280_ext_std \
	RCZ280_nat_std \
	RCZ280_zz80mb_std \
	RCZ280_zzrcc_std \
	RCZ280_rcbus_std \
	SCZ180_sc126_std \
	SCZ180_sc130_std \
	SCZ180_sc131_std \
	SCZ180_sc140_std \
	SCZ180_sc503_std \
	SCZ180_sc700_std \
	GMZ180_std \
	DYNO_std \
	RPH_std \
	Z80RETRO_std \
	SZ180_std \
	DUO_std \
	HEATH_std \
	EPITX_std \
	NABU_std \
	SZ80_std \
	SZ80_t35_std \
	MSX_std \
	MECB_std \
	UNA_std

#	MON_std

# $(info ROM: $(ROM))

# $(info "ROM: $(ROM))
# $(info "ROM_PLATFORM: $(ROM_PLATFORM))
# $(info "ROM_CONFIG: $(ROM_CONFIG))

# Below, as needed, a shell script is used to select
# the ROM identifier to be built.  The script generates
# a one line makefile that is subsequently included
# in this makefile.

ifndef ROM
    ROMFILE := rom.mk

    REAL_GOALS := $(filter-out clean,$(MAKECMDGOALS))
    ifeq ($(MAKECMDGOALS),)
        REAL_GOALS := all
    endif

    # When $(ROMFILE) is updated below, make will immediately
    # initiate a restart from scratch incorporating the updated
    # $(ROMFILE).

    ifneq ($(REAL_GOALS),)
        .DUMMY := $(shell chmod +x ./RomSel.sh)
        .DUMMY := $(shell ROMFILE="$(ROMFILE)" ROM_PLATFORM="$(ROM_PLATFORM)" ROM_CONFIG="$(ROM_CONFIG)" ./RomSel.sh </dev/tty >&2)
        ifeq ($(.SHELLSTATUS),0)
            include $(ROMFILE)
	else
            $(error No ROM configuration(s) specified for build!)
        endif
    endif
endif

# $(info ROM: $(ROM))

ifeq ($(ROM),dist)
    $(info )
    $(info *** DISTRIBUTION BUILD ***)
    $(info )
    OBJECTS := $(DIST_ROMS)
else
    OBJECTS := $(ROM)
endif

# $(info OBJECTS: $(OBJECTS))

# Convert the config file specification (<platform>_<config>)
# into the actual targets (*.rom, *.com, and *.upd).
# $(ROM) may contain multiple ROM identifiers to build.

OBJECTS := $(OBJECTS:=.rom) $(OBJECTS:=.com) $(OBJECTS:=.upd)
OBJECTS := $(filter-out UNA_%.com UNA_%.upd,$(OBJECTS))

# Proceed with normal RomWBW build makefile processing.

DEST := ../../Binary
TOOLS := ../../Tools
OTHERS := *.img *.rom *.com *.upd *.bin *.hex cpm.sys zsys.sys build.inc
OTHERS +=  *.build.inc font*.asm *.dat *.hbios_env.sh $(ROMFILE)

FONTS := font6x8c.asm font6x8u.asm font8x8c.asm font8x8u.asm \
	font8x11c.asm font8x11u.asm font8x16c.asm font8x16u.asm

include $(TOOLS)/Makefile.inc

# .SHELLFLAGS += -x
.NOTPARALLEL:

define BUILD_COMPONENT
	cp $(*F).build.inc build.inc ; \
	$(TASM) $1 $< $@ $(@:.bin=.lst) ; \
	rm build.inc
endef

font%.asm:
	@cp ../Fonts/$@ .

camel80.bin:
	@cp ../Forth/$@ .

tastybasic.bin:
	@cp ../TastyBasic/src/$@ .

sz180mon.bin:
	@$(ZXCC) $(CPM)/SLR180 -sz180mon/FH
	$(ZXCC) $(CPM)/MLOAD25 -sz180mon.bin=sz180mon

%.build.inc:
	@printf "\n\n\n*** Processing %s ***\n\n\n" $(*F)
	@echo $@ ; \
	echo "; RomWBW Configured for $(*F) at $$(date +%Y-%m-%d)" >>$@ ; \
	echo ";" >>$@ ; \
	echo "#DEFINE TIMESTAMP \"$$(date +%Y-%m-%d)\"" >>$@ ; \
	echo "#DEFINE CONFIG \"$(*F)\"" >>$@ ; \
	echo ";" >>$@ ; \
	echo "#INCLUDE \"Config/$(*F).asm\"" >>$@ ; \
	echo ";" >>$@

%.hbios_env.com: hbios_env.asm %.build.inc ; @$(call BUILD_COMPONENT, $(TASMFALGS) -dBASH)
%.usrrom.bin: usrrom.asm %.build.inc ; @$(call BUILD_COMPONENT)
%.updater.bin: updater.asm %.build.inc ; @$(call BUILD_COMPONENT)
%.eastaegg.bin: eastaegg.asm %.build.inc ; @$(call BUILD_COMPONENT)
%.game.bin: game.asm %.build.inc ; @$(call BUILD_COMPONENT)
%.nascom.bin: nascom.asm %.build.inc ; @$(call BUILD_COMPONENT)
%.romldr.bin: romldr.asm %.build.inc ; @$(call BUILD_COMPONENT)
%.dbgmon.bin: dbgmon.asm %.build.inc ; @$(call BUILD_COMPONENT)
%.sysconf.bin: ../Apps/sysconf/sysconf.asm %.build.inc ; @$(call BUILD_COMPONENT, -dHBIOS)
%.devlist.bin: ../Apps/devlist/devlist.asm %.build.inc ; @$(call BUILD_COMPONENT, -dHBIOS)
%.invntslc.bin: invntslc.asm %.build.inc ; @$(call BUILD_COMPONENT)
%.romfonts.bin: romfonts.asm %.build.inc ; @$(call BUILD_COMPONENT)

SZ180_%.hwmon.bin: sz180mon.bin
	@cp $< $@

%.hwmon.bin: hwmon.asm %.build.inc
	@$(call BUILD_COMPONENT)

DUO_%.netboot.mod: netboot-duo.mod
	@cp $< $@

%.netboot.mod: netboot-mt.mod
	@cp $< $@

%.hbios_env.sh: %.hbios_env.com
	@$(ZXCC) $< >$@

%.hbios_rom.bin: hbios.asm %.build.inc %.hbios_env.sh $(FONTS)
	@. ./$(*F).hbios_env.sh ; \
	case $$CPUFAM in 2) CPU="hd64180";; 3) CPU="z280";; *) CPU="z80";; esac ; \
	$(call BUILD_COMPONENT, -t $$CPU -dROMBOOT) ; \
	srec_cat $@ -Binary -Crop 0 0x7FFF -Checksum_Negative_Big_Endian 0x7FFF 1 1 -o $@ -Binary

%.hbios_app.bin: hbios.asm %.build.inc %.hbios_env.sh $(FONTS)
	@. ./$(*F).hbios_env.sh ; \
	case $$CPUFAM in 2) CPU="hd64180";; 3) CPU="z280";; *) CPU="z80";; esac ; \
	$(call BUILD_COMPONENT, -t $$CPU -dAPPBOOT)

UNA_%.rom1.bin: UNA_%.romldr.bin UNA_%.dbgmon.bin
	@cat UNA_$(*F).romldr.bin UNA_$(*F).dbgmon.bin ../ZSDOS/zsys_una.bin ../CPM22/cpm_una.bin >$@

%.rom1.bin: %.romldr.bin %.dbgmon.bin
	@cat $^ ../ZSDOS/zsys_wbw.bin ../CPM22/cpm_wbw.bin >$@ ; \
	srec_cat $@ -Binary -Crop 0 0x7FFF -Checksum_Negative_Big_Endian 0x7FFF 1 1 -o $@ -Binary

%.rom2.bin: camel80.bin %.nascom.bin tastybasic.bin %.game.bin %.eastaegg.bin %.netboot.mod %.updater.bin %.sysconf.bin %.usrrom.bin
	@cat $^ >$@ ; \
	srec_cat $@ -Binary -Crop 0 0x7FFF -Checksum_Negative_Big_Endian 0x7FFF 1 1 -o $@ -Binary

%.rom3.bin: %.hwmon.bin %.devlist.bin %.invntslc.bin %.romfonts.bin
	@cat $^ >$@ ; \
	srec_cat $@ -Binary -Crop 0 0x7FFF -Checksum_Negative_Big_Endian 0x7FFF 1 1 -o $@ -Binary

UNA_%.rom: UNA_%.hbios_env.sh UNA_%.rom1.bin
	@. ./UNA_$(*F).hbios_env.sh ; \
	cat ../UBIOS/UNA-BIOS.BIN UNA_$(*F).rom1.bin ../UBIOS/FSFAT.BIN ../RomDsk/rom$${ROMDISKSIZE}_una.dat >$@ ; \
	cp UNA_$(*F).rom1.bin $(DEST)/UNA_WBW_SYS.bin ; \
	cp ../RomDsk/rom$${ROMDISKSIZE}_una.dat $(DEST)/UNA_WBW_ROM$${ROMDISKSIZE}.bin

%.rom: %.hbios_env.sh %.hbios_rom.bin %.rom1.bin %.rom2.bin %.rom3.bin
	@. ./$(*F).hbios_env.sh ; \
	if [ $$ROMSIZE -gt 0 ] ; then RD="rom$$ROMDISKSIZE" ; else RD="rom$$RAMDISKSIZE" ; fi ; \
	cat $(*F).hbios_rom.bin $(*F).rom1.bin $(*F).rom2.bin $(*F).rom3.bin ../RomDsk/$${RD}_wbw.dat >$@

%.com: %.hbios_app.bin %.romldr.bin %.dbgmon.bin
	@cat $(*F).hbios_app.bin $(*F).romldr.bin $(*F).dbgmon.bin ../ZSDOS/zsys_wbw.bin >$@

%.upd: %.hbios_rom.bin %.rom1.bin %.rom2.bin %.rom3.bin
	@cat $(*F).hbios_rom.bin $(*F).rom1.bin $(*F).rom2.bin $(*F).rom3.bin >$@
