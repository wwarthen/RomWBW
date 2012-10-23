
# GCC based makefile
#
# 06/18/2012 2.0 dgg - updated for v2.0
#
# 02/22/2012 1.5 dgg - modified for assembly under Linux
#
# 01/11/2011 1.4 wbw - added support for ZSDOS/ZDDOS/ZCPR
#
# 12/22/2011 1.3 wbw - removed all built-in config stuff, operation is now entirely
#                      dependent on variables CONFIG, ROMSIZE, and CPU
#
# 12/02/2011 1.3 wbw - replaced makever functionality with built-in makefile stuff
#
# 11/29/2011 1.3 dwg - uses makever to generate stdincl.inc from the version.hpp file
#
# 11/19/2011 1.3 dwg - added n8vem_vdu to "usage" and "all" rules
#                      enhanced clean to get files in $(OUTDIR)
#                      added custom to "all" rule

#
# The operation of this makefile is entirely dependent on the setting
# of three variables: CONFIG, ROMSIZE, and CPU:
#
# CONFIG determines which configuration to build which means that
# it will determine the config_xxx.asm config settings file to
# include as well as the output file names.  So, for example,
# if CONFIG is "n8vem", the config_n8vem.asm file will be used
# for BIOS configuration settings and the output files will be
# n8vem.rom, n8vem.sys, and n8vem.com.
#
# ROMSIZE specifies the size of the ROM image to be produced and
# currently must be either "1024" for a 1MB ROM or "512" for a
# 512KB ROM.
#
# CPU specifies the instruction set to be used in assembly and
# must be either "80" for Z80 or "180" for Z180.  Currently,
# you should use 180 for N8 ROMs and 80 for everything else.
#
# SYS specifies the system variant to build in.  CPM will
# build traditional CP/M.  ZSYS will build ZSystem which
# currently means ZSDOS 1.2 & ZCPR 1.0
#
# ROMNAME names the output file.  It defaults to
# CONFIG.  The output of the build will be:
# <ROMNAME>.rom, <ROMNAME>.sys, and <ROMNAME>.com.
#
# These variables can be passed into the makefile by the command
# line, hardcoded in this file, or set as environment variables
# in the OS.  To use a command line, use the following format:
#
#   make CONFIG=<config> ROMSIZE=<romsize> CPU=<cpu> SYS=<sys> ROMNAME=<romname>
#
# An example of this is:
#
#   make CONFIG=n8vem ROMSIZE=512 CPU=80 SYS=CPM ROMNAME=n8vem
#
# Alternatively, you can specify the variables by hardcoding them
# in this file.  To do so, uncomment the five lines after these
# comments and change the values as desired.
# If the variables are specified this way, you would then invoke
# the make by simply using "make"
#
# If you want to set them as environment variables, you can
# do this with commands like the following at an OS command
# prompt or in a batch file:
#
#   SET CONFIG=n8vem
#   SET ROMSIZE=512
#   SET CPU=80
#   SET SYS=CPM
#   SET ROMNAME=n8vem
#
# Note: use "make clean" to delete temporary and output files
#
# A good idea is to do a clean with every build and this can be
# accomplished on one command line doing something like this:
#
#   make clean all CONFIG=n8vem ROMSIZE=512 CPU=80 SYS=CPM ROMNAME=n8vem
#
# or, if you are using hard coded variables above:
#
#   make clean all
#
# Uncomment and update values below to hardcode settings:
#
#CONFIG := n8vem
#ROMSIZE := 512
#CPU := 80
#SYS := CPM
#ROMNAME := n8vem

# Dougs Configuration
CONFIG  := zeta
ROMSIZE := 512
CPU     := 80
SYS     := CPM
ROMNAME := dougzeta

ifndef ROMNAME
ROMNAME := $(CONFIG)
endif

CPMCP := bin/cpmcp

ROMDSKFILES := ../RomDsk/$(SYS)_$(ROMSIZE)KB/*.* ../RomDsk/cfg_$(CONFIG)/*.* ../RomDsk/RomApps/*.*

ifeq "$(SYS)" "CPM"
DOSBIN := bdosb01.bin
CPBIN := ccpb03.bin
CPASM := ccpb03.asm
else
DOSBIN := zsdos.bin
CPBIN := zcprw.bin
CPASM := zcprw.asm
endif

OUTDIR := ../Output

TASM := bin/tasm
TASMTABS := bin
export TASMTABS

ASMOPT80 := -t$(CPU) -g3
ASMOPT85 := -t85 -g3 

ASM80 := $(TASM) $(ASMOPT80) -b 
ASM85 := $(TASM) $(ASMOPT85)
ASMIMG := $(TASM) $(ASMOPT80) -b -fE5

NULL :=
SPACE := ${NULL} ${NULL}

%.bin: %.asm
	$(ASM80) -b $< $@
	
%.com: %.asm
	$(ASM80) $< $@
	
%.img: %.asm
	$(ASMIMG) $< $@

%.exe:	%.cpp
	$(CC) $< -o $@

ifneq ($(MAKECMDGOALS),clean)
ifeq "$(and $(CONFIG), $(ROMSIZE), $(CPU), $(SYS), $(ROMNAME))" ""
$(error Usage: make CONFIG=<config> ROMSIZE=[512|1024] CPU=[80|180] SYS=[CPM|ZSYS] ROMNAME=<romname>)
endif
endif

all: $(OUTDIR)/$(ROMNAME).rom $(OUTDIR)/$(ROMNAME).sys $(OUTDIR)/$(ROMNAME).com

build.inc:
	echo	';' >$@
	/bin/echo -n '; RomWBW Configured for '$(CONFIG)' ' >>$@
	date >> $@
	echo	; >>$@
	/bin/echo -n '#DEFINE	TIMESTAMP	"' >>$@
	date '+%Y%m%d%H%M"' >>$@
	echo	; >>$@
	echo  '#DEFINE	VARIANT		"WBW-$(USERNAME)"' >>$@
	echo	; >>$@
	echo	ROMSIZE		.EQU	$(ROMSIZE) >>$@
	echo	; >>$@
	echo	'#INCLUDE	"config_'$(CONFIG)'.asm"' >>$@
	echo	; >>$@

#loader.bin:	loader.asm util.asm
#	$(TASM) $(ASMOPT80) -b $<

loader.bin:	loader.asm util.asm

loader.asm:	../Source/loader.asm
	cp $< .
	bin/cvt2mac $@

bnk1.asm:	../Source/bnk1.asm
	cp $< .
	bin/cvt2mac $@

bdosb01.asm:	../Source/bdosb01.asm
	cp $< .
	bin/cvt2mac $@

bootrom.bin : bootrom.asm memmgr.asm std.asm build.inc ver.inc
	$(TASM) $(ASMOPT80) $< $@

bootrom.asm:	../Source/bootrom.asm config_$(CONFIG).asm
	cp $< .
	bin/cvt2mac $@
	
bootapp.bin : bootapp.asm std.asm build.inc ver.inc
	$(TASM) $(ASMOPT80) $< $@

bootapp.asm:	../Source/bootapp.asm
	cp $< .
	bin/cvt2mac $@

cbios.asm:	../Source/cbios.asm
	cp $< .
	bin/cvt2mac $@



config_$(CONFIG).asm:	../Source/config_$(CONFIG).asm
	cp $< .
	bin/cvt2mac $@

cnfgdata.inc:	../Source/cnfgdata.inc
	cp $< .
	bin/cvt2mac $@

dbgmon.asm:	../Source/dbgmon.asm
	cp $< .
	bin/cvt2mac $@

fd.asm:		../Source/fd.asm
	cp $< .
	bin/cvt2mac $@

fd_data.asm:	../Source/fd_data.asm
	cp $< .
	bin/cvt2mac $@

#hbios.asm:	../Source/hbios.asm
#	cp $< .
#	bin/cvt2mac $@

hbfill.asm:	../Source/hbfill.asm
	cp $< .
	bin/cvt2mac $@

ide.asm:	../Source/ide.asm
	cp $< .
	bin/cvt2mac $@

ide_data.asm:	../Source/ide_data.asm
	cp $< .
	bin/cvt2mac $@

infolist.inc:	../Source/infolist.inc
	cp $< .
	bin/cvt2mac $@

memmgr.asm:	../Source/memmgr.asm
	cp $< .
	bin/cvt2mac $@

pgzero.bin : pgzero.asm std.asm build.inc ver.inc
	$(TASM) $(ASMOPT80) $< $@

pgzero.asm:	../Source/pgzero.asm
	cp $< .
	bin/cvt2mac $@ 

ppide.asm:	../Source/ppide.asm
	cp $< .
	bin/cvt2mac $@

ppide_data.asm:	../Source/ppide_data.asm
	cp $< .
	bin/cvt2mac $@

ppp.asm:	../Source/ppp.asm
	cp $< .
	bin/cvt2mac $@

ppp_data.asm:	../Source/ppp_data.asm
	cp $< .
	bin/cvt2mac $@

prefix.asm:	../Source/prefix.asm
	cp $< .
	bin/cvt2mac $@

prp.asm:	../Source/prp.asm
	cp $< .
	bin/cvt2mac $@

prp_data.asm:	../Source/prp_data.asm
	cp $< .
	bin/cvt2mac $@

romfill.bin:	romfill.asm
	$(TASM) $(ASMOPT80) -b $< $@

romfill.asm:	../Source/romfill.asm
	cp $< .
	bin/cvt2mac $@

sd.asm:		../Source/sd.asm
	cp $< .
	bin/cvt2mac $@

sd_data.asm:	../Source/sd_data.asm
	cp $< .
	bin/cvt2mac $@
	
std.asm:	../Source/std.asm
	cp $< .
	bin/cvt2mac $@

syscfg.asm:	../Source/syscfg.asm
	cp $< .
	bin/cvt2mac $@

uart.asm:	../Source/uart.asm
	cp $< .
	bin/cvt2mac $@

util.bin:	util.asm

util.asm:	../Source/util.asm
	cp $< .
	bin/cvt2mac $@

vdu.asm:	../Source/vdu.asm
	cp $< .
	bin/cvt2mac $@

ver.inc:	../Source/ver.inc
	cp $< .
	bin/cvt2mac $@

zcprw.bin : zcprw.asm zcpr.asm
	$(TASM) $(ASMOPT85) $< $@
	
zsdos.bin : zsdos.asm zsdos.lib zsdos-gp.z80
	$(TASM) $(ASMOPT80) $< $@

hbfill.bin: hbfill.asm fd.asm ide.asm ppide.asm sd.asm prp.asm ppp.asm std.asm ver.inc build.inc

cbios.bin: cbios.asm fd_data.asm ide_data.asm ppide_data.asm sd_data.asm prp_data.asm ppp_data.asm uart.asm vdu.asm std.asm ver.inc build.inc infolist.inc
	$(ASM80) -b -dBLD_SYS=SYS_$(SYS) $< $@

cbios.asm:	../Source/cbios.asm
	cp $< .
	bin/cvt2mac $@

dbgmon.bin: dbgmon.asm hbfill.bin std.asm ver.inc build.inc

syscfg.bin: syscfg.asm std.asm build.inc ver.inc cnfgdata.inc

$(CPASM):	../Source/$(CPASM)
	cp $< .
	bin/cvt2mac $@
	
$(OUTDIR)/$(ROMNAME).rom:	diskdefs rom0.bin rom1.bin $(ROMDISKFILES) $(OUTDIR)/$(ROMNAME).sys blank$(ROMSIZE)KB.dat
	for d in ../Apps/*; do \
	    if test -e $$d/*.com; then \
		cp $$d/*.com ../RomDsk/RomApps; \
	    fi; \
	done;
	for d in ../Apps/*; do \
	    if test -e $$d/*.man; then \
		cp $$d/*.man ../RomDsk/RomApps; \
	    fi; \
	done;
	for d in ../Apps/*; do \
	    if test -e $$d/*.bsp; then \
		cp $$d/*.bsp ../RomDsk/RomApps; \
	    fi; \
	done;
	cp blank$(ROMSIZE)KB.dat RomDisk.tmp
	$(CPMCP) -f rom$(ROMSIZE)KB RomDisk.tmp $(ROMDSKFILES) 0:
	$(CPMCP) -f rom$(ROMSIZE)KB RomDisk.tmp ../Output/$(ROMNAME).sys 0:$(SYS).sys
	cat rom0.bin rom1.bin RomDisk.tmp >>$@

diskdefs:	bin/diskdefs
	cp bin/diskdefs .
	bin/cvt2mac diskdefs

$(OUTDIR)/$(ROMNAME).com: bootapp.bin syscfg.bin loader.bin bnk1.bin dbgmon.bin sys.bin
	cat bootapp.bin syscfg.bin loader.bin bnk1.bin dbgmon.bin sys.bin >>$@

$(OUTDIR)/$(ROMNAME).sys:	prefix.bin sys.bin
	cat prefix.bin sys.bin >>$(OUTDIR)/$(ROMNAME).sys

rom0.bin:	pgzero.bin bootrom.bin syscfg.bin loader.bin romfill.bin dbgmon.bin sys.bin hbfill.bin
	cat $< >>rom0.bin

rom1.bin:	pgzero.bin bootrom.bin syscfg.bin loader.bin bnk1.bin
	cat $< >>rom1.bin

sys.bin:	$(CPBIN) $(DOSBIN) cbios.bin hbfill.bin ccpb03.bin
	echo at sys.bin target, about to cat
	cat $(CPBIN) $(DOSBIN) cbios.bin hbfill.bin >>$@

prefix.bin:	prefix.asm

blank512KB.dat:	../Source/blank512KB.dat
	cp $< .

blank1024KB.dat:	../Source/blank1024KB.dat
	cp $< .

#cbios.asm:	../Source/cbios.asm
#	cp $< .
#	bin/cvt2mac $@

ccpb03.asm:	../Source/ccpb03.asm
	cp $< .
	bin/cvt2mac $@

clean:
	rm -f *.asm *.obj *.bin *.com *.img *.rom *.lst *.exp *.tmp *.inc
	rm -f $(OUTDIR)/*.*
	rm -f ../RomDsk/RomApps/*.*
	rm -f diskdefs
	rm -f blank$(ROMSIZE)KB.dat

