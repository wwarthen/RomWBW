# RomWBW/branches/s100/XSource/Makefile 1/19/2013 dgw - 
#   This makefile is a preliminary build script for the new std.asm schema.
#   It currently builds the zeta and n8_2312 platforms and work on the
#   n8vem platform is in progress but not working yet.

# RomWBW/branches/dwg/XSource/Makefile  1/16/2013 dwg - validate build on Linux
# RomWBW/branches/dwg/XSource/Makefile 11/09/2012 dwg - add copy rule for n8chars.inc
# RomWBW/branches/dwg/XSource/Makefile 10/24/2012 dwg - 
#
# GCC based makefile
#
# 09/28/2012 2.2 dwg - updated for Mac OS X 10.8.2 Mountain Lion
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
# SET CONFIG=zeta
# SET ROMSIZE=512
# SET CPU=80
# SET SYS=CPM
# SET ROMNAME=zeta
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


# 1/19/2013 dwg - tested zeta, 

#CONFIG := zeta
#ROMSIZE := 512
#CPU := 180
#SYS := CPM
#ROMNAME := zeta

CONFIG := n8_2312
ROMSIZE := 512
CPU := 180
SYS := CPM
ROMNAME := n8_2312

#CONFIG := N8VEM
#ROMSIZE := 512
#CPU := 180
#SYS := CPM
#ROMNAME := N8VEM



ifndef ROMNAME
ROMNAME := $(CONFIG)
endif

CPMCP := bin/cpmcp
CVT := bin/CVT2MAC
SRC := ../Source/

ROMDSKFILES := ../RomDsk/$(SYS)_$(ROMSIZE)KB/*.* ../RomDsk/cfg_$(CONFIG)/*.* ../Apps/core/*.*

ifeq "$(SYS)" "CPM"
DOSBIN := bdosb01.bin
CPBIN := ccpb03.bin
else
DOSBIN := zsdos.bin
CPBIN := zcprw.bin
endif

OUTDIR := ../Output

TASM := bin/TASM 
TASMTABS := bin
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

STDS = std-n8.inc std-n8vem.inc std-s100.inc std-s2i.inc std-zeta.inc

all: $(STDS) tasm80.tab tasm85.tab $(OUTDIR)/$(ROMNAME).rom $(OUTDIR)/$(ROMNAME).sys $(OUTDIR)/$(ROMNAME).com
	rm  -f *.asm
	rm  -f *.bin
	rm  -f *.inc *.tab *.tmp
	rm  -f diskdefs *.exp

tasm80.tab:	bin/TASM80.TAB
	cp bin/TASM80.TAB tasm80.tab

tasm85.tab:	bin/TASM85.TAB
	cp bin/TASM85.TAB tasm85.tab


build.inc:
	/bin/echo	';' >$@
	/bin/echo -n '; RomWBW Configured for '$(CONFIG)' ' >>$@
	date >> $@
	/bin/echo	; >>$@
	/bin/echo -n '#DEFINE	TIMESTAMP	"' >>$@
	date '+%Y %m %d %H%M"' >>$@
	/bin/echo	; >>$@
	/bin/echo  '#DEFINE	VARIANT		"WBW-$(USERNAME)"' >>$@
	/bin/echo	; >>$@
	/bin/echo	ROMSIZE		.EQU	$(ROMSIZE) >>$@
	/bin/echo	; >>$@
	/bin/echo	'#INCLUDE	"config_'$(CONFIG)'.asm"' >>$@
	/bin/echo	; >>$@

# 12/31/2012 dwg - added xio.asm as dependency
bootrom.bin : bootrom.asm std.asm build.inc ver.inc memmgr.asm config_$(CONFIG).asm xio.asm
	$(TASM) $(ASMOPT80) $< $@
	
bootapp.bin:	bootapp.asm std.asm build.inc ver.inc
	$(TASM) $(ASMOPT80) $< $@
	
pgzero.bin:	pgzero.asm std.asm build.inc ver.inc
	$(TASM) $(ASMOPT80) $< $@
	
zcprw.bin:	zcprw.asm zcpr.asm
	$(TASM) $(ASMOPT85) $< $@
	
zsdos.bin:	zsdos.asm zsdos.lib zsdos-gp.z80
	$(TASM) $(ASMOPT80) $< $@

cbios.bin: cbios.asm fd_data.asm ide_data.asm ppide_data.asm sd_data.asm prp_data.asm ppp_data.asm uart.asm vdu.asm std.asm ver.inc build.inc infolist.inc
	$(TASM) $(ASMOPT80) -dBLD_SYS=SYS_$(SYS) $< $@

dbgmon.bin: dbgmon.asm std.asm ver.inc build.inc

syscfg.bin: syscfg.asm std.asm build.inc ver.inc

os.bin: $(CPBIN) $(DOSBIN) cbios.bin
	cat $(CPBIN) $(DOSBIN) cbios.bin >>$@
 	
rom0.bin: pgzero.bin bootrom.bin syscfg.bin loader.bin romfill.bin dbgmon.bin os.bin hbfill.bin
	cat pgzero.bin bootrom.bin syscfg.bin loader.bin romfill.bin dbgmon.bin os.bin hbfill.bin >>$@

# fixed 1/16/20113 dwg - added hbios.bin to end of cat list	
rom1.bin:	pgzero.bin bootrom.bin syscfg.bin loader.bin hbios.bin
	cat     pgzero.bin bootrom.bin syscfg.bin loader.bin hbios.bin >>$@

$(OUTDIR)/$(ROMNAME).rom: rom0.bin rom1.bin $(ROMDISKFILES) $(OUTDIR)/$(ROMNAME).sys diskdefs
	cp $(SRC)blank$(ROMSIZE)KB.dat RomDisk.tmp
	$(CPMCP) -f rom$(ROMSIZE)KB RomDisk.tmp $(ROMDSKFILES) 0:
	$(CPMCP) -f rom$(ROMSIZE)KB RomDisk.tmp ../Output/$(ROMNAME).sys 0:$(SYS).sys
	cat rom0.bin rom1.bin RomDisk.tmp >>$@

$(OUTDIR)/$(ROMNAME).com: bootapp.bin syscfg.bin loader.bin hbios.bin dbgmon.bin os.bin
	cat bootapp.bin syscfg.bin loader.bin hbios.bin dbgmon.bin os.bin >>$@

$(OUTDIR)/$(ROMNAME).sys: prefix.bin os.bin
	cat prefix.bin os.bin >>$@

ansi.asm:	$(SRC)ansi.asm
	cp $< $@
	$(CVT) $@

bdosb01.asm:	$(SRC)bdosb01.asm
	cp $< $@
	$(CVT) $@

hbios.asm:	$(SRC)hbios.asm kbd.asm fd.asm ppide.asm n8v.asm n8chars.inc ppk.asm sd.asm tty.asm ansi.asm
	cp $(SRC)hbios.asm $@
	$(CVT) $@

bootapp.asm:	$(SRC)bootapp.asm
	cp $< $@
	$(CVT) $@

bootrom.asm:	$(SRC)bootrom.asm
	cp $< $@
	$(CVT) $@

cbios.asm:	$(SRC)cbios.asm
	cp $< $@
	$(CVT) $@

ccpb03.asm:	$(SRC)ccpb03.asm
	cp $< $@
	$(CVT) $@

cnfgdata.inc:	$(SRC)cnfgdata.inc
	cp $< $@
	$(CVT) $@

config_$(CONFIG).asm:	$(SRC)config_$(CONFIG).asm
	cp $< $@
	$(CVT) $@

dbgmon.asm:	$(SRC)dbgmon.asm
	cp $< $@
	$(CVT) $@

diskdefs:	$(SRC)diskdefs
	cp $< $@
	$(CVT) $@

fd.asm:	$(SRC)fd.asm
	cp $< $@
	$(CVT) $@

fd_data.asm:	$(SRC)fd_data.asm
	cp $< $@
	$(CVT) $@

hbfill.asm:	$(SRC)hbfill.asm
	cp $< $@
	$(CVT) $@

ide_data.asm:	$(SRC)ide_data.asm
	cp $< $@
	$(CVT) $@

infolist.inc:	$(SRC)infolist.inc
	cp $< $@
	$(CVT) $@

kbd.asm:		$(SRC)kbd.asm
	cp $< $@
	$(CVT) $@

loader.asm:	$(SRC)loader.asm util.asm
	cp $(SRC)loader.asm $@
	$(CVT) $@

memmgr.asm:	$(SRC)memmgr.asm
	cp $< $@
	$(CVT) $@

n8chars.inc:	$(SRC)n8chars.inc
	cp $< $@
	$(CVT) $@

n8v.asm:	$(SRC)n8v.asm
	cp $< $@
	$(CVT) $@

pgzero.asm:	$(SRC)pgzero.asm
	cp $< $@
	$(CVT) $@

ppide.asm:	$(SRC)ppide.asm
	cp $< $@
	$(CVT) $@

ppide_data.asm:	$(SRC)ppide_data.asm
	cp $< $@
	$(CVT) $@

ppk.asm:	$(SRC)ppk.asm
	cp $< $@
	$(CVT) $@

ppp_data.asm:	$(SRC)ppp_data.asm
	cp $< $@
	$(CVT) $@

prefix.asm:	$(SRC)prefix.asm
	cp $< $@
	$(CVT) $@

prp_data.asm:	$(SRC)prp_data.asm
	cp $< $@
	$(CVT) $@

romfill.asm:	$(SRC)romfill.asm
	cp $< $@
	$(CVT) $@

sd.asm:	$(SRC)sd.asm
	cp $< $@
	$(CVT) $@

sd_data.asm:	$(SRC)sd_data.asm
	cp $< $@
	$(CVT) $@

std.asm:	$(SRC)std.asm
	cp $< $@
	$(CVT) $@

std-n8.inc:	$(SRC)std-n8.inc
	cp $< $@
	$(CVT) $@
	
std-n8vem.inc:	$(SRC)std-n8vem.inc 
	cp $< $@
	$(CVT) $@

std-s100.inc:	$(SRC)std-s100.inc
	cp $< $@
	$(CVT) $@

std-s2i.inc:	$(SRC)std-s2i.inc
	cp $< $@
	$(CVT) $@

std-zeta.inc:	$(SRC)std-zeta.inc
	cp $< $@
	$(CVT) $@

syscfg.asm:	$(SRC)syscfg.asm config_$(CONFIG).asm cnfgdata.inc
	cp $< $@
	$(CVT) $@

tty.asm:	$(SRC)tty.asm
	cp $< $@
	$(CVT) $@

uart.asm:	$(SRC)uart.asm
	cp $< $@
	$(CVT) $@

util.asm:	$(SRC)util.asm
	cp $< $@
	$(CVT) $@

vdu.asm:	$(SRC)vdu.asm
	cp $< $@
	$(CVT) $@

ver.inc:	$(SRC)ver.inc
	cp $< $@
	$(CVT) $@

xio.asm:	$(SRC)xio.asm
	cp $< $@
	$(CVT) $@

clean:
	rm -f *.tab *.TAB *.inc *.asm *.bin *.com *.img *.rom *.lst *.exp *.tmp
	rm -f build.inc diskdefs *.inc
	rm -f $(OUTDIR)/*.*
