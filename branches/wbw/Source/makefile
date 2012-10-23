#
# GCC based makefile
#
# 05/24/2012 2.0 wbw - changed to handle HBIOS
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

ifndef ROMNAME
ROMNAME := $(CONFIG)
endif

CPMTOOLSPATH := ../tools/cpmtools
CPMCP := $(CPMTOOLSPATH)/cpmcp.exe

ROMDSKFILES := ../RomDsk/$(SYS)_$(ROMSIZE)KB/*.* ../RomDsk/cfg_$(CONFIG)/*.* ../Apps/core/*.*

ifeq "$(SYS)" "CPM"
DOSBIN := bdosb01.bin
CPBIN := ccpb03.bin
else
DOSBIN := zsdos.bin
CPBIN := zcprw.bin
endif

OUTDIR := ..\Output

TASMPATH := ../tools/tasm32
TASM := $(TASMPATH)/tasm.exe
TASMTABS := $(TASMPATH)
export TASMTABS

ASMOPT80 := -t$(CPU) -g3
ASMOPT85 := -t85 -g3

ASM80 := $(TASM) $(ASMOPT80)
ASM85 := $(TASM) $(ASMOPT85)
ASMIMG := $(TASM) $(ASMOPT80) -b -fE5

NULL :=
SPACE := ${NULL} ${NULL}

%.bin: %.asm
	$(ASM80) $< $@
	
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

all: $(OUTDIR)\$(ROMNAME).rom $(OUTDIR)\$(ROMNAME).sys $(OUTDIR)\$(ROMNAME).com

build.inc:
	echo	; >$@
	echo	; RomWBW Configured for $(CONFIG), %date% %time% >>$@
	echo	; >>$@
	echo	#DEFINE	TIMESTAMP	"%date:~-4,4%%date:~-10,2%%date:~-7,2%T%time:~0,2%%time:~3,2%" >>$@
	echo	#DEFINE	VARIANT		"WBW-%username%" >>$@
	echo	; >>$@
	echo	ROMSIZE		.EQU	$(ROMSIZE) >>$@
	echo	; >>$@
	echo	#INCLUDE	"config_$(CONFIG).asm" >>$@
	echo	; >>$@
	
bootrom.bin : bootrom.asm std.asm build.inc ver.inc
	$(TASM) $(ASMOPT80) $< $@
	
bootapp.bin : bootapp.asm std.asm build.inc ver.inc
	$(TASM) $(ASMOPT80) $< $@
	
pgzero.bin : pgzero.asm std.asm build.inc ver.inc
	$(TASM) $(ASMOPT80) $< $@
	
zcprw.bin : zcprw.asm zcpr.asm
	$(TASM) $(ASMOPT85) $< $@
	
zsdos.bin : zsdos.asm zsdos.lib zsdos-gp.z80
	$(TASM) $(ASMOPT80) $< $@

cbios.bin: cbios.asm fd_data.asm ide_data.asm ppide_data.asm sd_data.asm prp_data.asm ppp_data.asm uart.asm vdu.asm std.asm ver.inc build.inc
	$(TASM) $(ASMOPT80) -dBLD_SYS=SYS_$(SYS) $< $@

dbgmon.bin: dbgmon.asm std.asm ver.inc build.inc

syscfg.bin: syscfg.asm std.asm build.inc ver.inc

os.bin: $(CPBIN) $(DOSBIN) cbios.bin
	copy /B $(subst $(SPACE),+,$(^)) $@
	
rom0.bin: pgzero.bin bootrom.bin syscfg.bin loader.bin romfill.bin dbgmon.bin os.bin hbfill.bin
	copy /B $(subst $(SPACE),+,$(^)) $@
	
rom1.bin: pgzero.bin bootrom.bin syscfg.bin loader.bin bnk1.bin
	copy /B $(subst $(SPACE),+,$(^)) $@

$(OUTDIR)\$(ROMNAME).rom: rom0.bin rom1.bin $(ROMDISKFILES) $(OUTDIR)\$(ROMNAME).sys
	copy blank$(ROMSIZE)KB.dat RomDisk.tmp
	$(CPMCP) -f rom$(ROMSIZE)KB RomDisk.tmp $(ROMDSKFILES) 0:
	$(CPMCP) -f rom$(ROMSIZE)KB RomDisk.tmp ../Output/$(ROMNAME).sys 0:$(SYS).sys
	copy /B rom0.bin+rom1.bin+RomDisk.tmp $@

$(OUTDIR)\$(ROMNAME).com: bootapp.bin syscfg.bin loader.bin bnk1.bin dbgmon.bin os.bin
	copy /B $(subst $(SPACE),+,$(^)) $@

$(OUTDIR)\$(ROMNAME).sys: prefix.bin os.bin
	copy /B $(subst $(SPACE),+,$(^)) $@

clean:
	if exist *.bin del *.bin
	if exist *.com del *.com
	if exist *.img del *.img
	if exist *.rom del *.rom
	if exist *.lst del *.lst
	if exist *.exp del *.exp
	if exist *.tmp del *.tmp
	if exist build.inc del build.inc
	if exist $(OUTDIR)\*.* erase /Q $(OUTDIR)\*.*