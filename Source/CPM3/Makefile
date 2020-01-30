OBJECTS = cpmldr.com cpm3res.sys cpm3bnk.sys
BIOS = bios3.spr bnkbios3.spr
BIOSOBJS = bioskrnl.rel scb.rel boot.rel chario.rel \
	move.rel drvtbl.rel diskio.rel
COMMA := ,
NULL :=
SPACE := $(NULL) $(NULL)
BIOSNAMES := $(subst $(SPACE),$(COMMA),$(basename $(BIOSOBJS)))
CONFS = options.lib gencpm.dat
OTHERS = $(CONFS) $(BIOS) $(BIOSOBJS) cpm3.sys biosldr.rel cpmldr.rel

TOOLS=../../Tools
include $(TOOLS)/Makefile.inc

cpmldr.com: cpmldr.rel biosldr.rel
	$(ZXCC) $(TOOLS)/cpm/bin/LINK -cpmldr[L100]=cpmldr,biosldr
	#rm -f biosldr.rel cpmldr.rel
	rm -f cpmldr.sym

cpm3res.sys:
	rm *.rel
	cp optres.lib options.lib
	cp genres.dat gencpm.dat
	make bios3.spr
	$(ZXCC) gencpm -auto -display
	mv cpm3.sys cpm3res.sys
	
cpm3bnk.sys:
	rm *.rel
	cp optres.lib options.lib
	cp genres.dat gencpm.dat
	make bnkbios3.spr
	$(ZXCC) gencpm -auto -display
	mv cpm3.sys cpm3bnk.sys

bios3.spr: $(BIOSOBJS)
	$(ZXCC) $(TOOLS)/cpm/bin/LINK -bios3[OS]=$(BIOSNAMES)

bnkbios3.spr: $(BIOSOBJS)
	$(ZXCC) $(TOOLS)/cpm/bin/LINK -bnkbios3[B]=$(BIOSNAMES)

# 
# rem Update cpm_hd.img
# echo.
# echo.
# echo *** Update Disk Image ***
# echo.
# for %%f in (
#   cpmldr.com
#   ccp.com
#   gencpm.com
#   genres.dat
#   genbnk.dat
#   bios3.spr
#   bnkbios3.spr
#   bdos3.spr
#   bnkbdos3.spr
#   resbdos3.spr
#   cpm3res.sys
#   cpm3bnk.sys
#   gencpm.dat
#   cpm3.sys
#   readme.1st
#   cpm3fix.pat
# ) do call :upd_img %%f
# 
# goto :eof
# 
# :upd_img
# echo   %1...
# cpmrm.exe -f wbw_hd0 ../../Binary/hd_cpm3.img 0:%1
# cpmcp.exe -f wbw_hd0 ../../Binary/hd_cpm3.img %1 0:%1
# goto :eof@echo off
# setlocal
# 
# if exist bios3.spr del bios3.spr
# if exist bnkbios3.spr del bnkbios3.spr
# if exist *.rel del *.rel
# if exist cpmldr.com del cpmldr.com
# if exist *.err del *.err
# if exist *.lst del *.lst
# if exist *.sym del *.sym
# if exist *.sys del *.sys
# if exist gencpm.dat del gencpm.dat
# if exist options.lib del options.lib
