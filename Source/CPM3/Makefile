#
# this makefile does double duty.  it serves as the top level make
# and as the invoked make for the different ways that the cpm3 is built
#
# it does this by overriding OBJECTS in an invoked sub-make
#
OBJECTS = cpmldr.com cpmldr.sys cpm3res.sys cpm3bnk.sys zpmbios3
OBJECTS += ccp.com gencpm.com genres.dat genbnk.dat
OBJECTS += bdos3.spr bnkbdos3.spr resbdos3.spr
OBJECTS += readme.1st cpm3fix.pat cpm3.sys gencpm.dat
NOCOPY = zpmbios3
OTHERS = cpmldr.rel biosldr.rel cpm3res.sys cpm3bnk.sys loader.bin cpmldr.bin
OTHERS += biosldrc.rel biosldrd.rel
NODELETE = ccp.com gencpm.com genres.dat genbnk.dat bdos3.spr bnkbdos3.spr resbdos3.spr
NODELETE += readme.1st cpm3fix.pat
NODIFF = zpmbios3

DEST = ../../Binary/CPM3
TOOLS = ../../Tools

include $(TOOLS)/Makefile.inc

export INCDIR80 = ../

BIOSOBJS = bioskrnl.rel scb.rel boot.rel chario.rel 
BIOSOBJS += move.rel drvtbl.rel diskio.rel util.rel
COMMA := ,
NULL :=
SPACE := $(NULL) $(NULL)
BIOSNAMES := $(subst $(SPACE),$(COMMA),$(basename $(BIOSOBJS)))

DEFCPM3 = bnk
#DEFCPM3 = res

clean:: biosclean
	@rm -f bios3.spr bnkbios3.spr zpmbios3.spr cpmldr.com gencpm.dat options.lib ldropts.lib
	
biosclean:
	@rm -f $(BIOSOBJS)

cpm3res.sys:
	make biosclean
	cp optres.lib options.lib
	cp genres.dat gencpm.dat
	make OBJECTS=bios3.spr
	$(ZXCC) gencpm -auto -display
	mv cpm3.sys cpm3res.sys
	rm gencpm.dat

cpm3bnk.sys:
	make biosclean
	cp optbnk.lib options.lib
	cp genbnk.dat gencpm.dat
	make OBJECTS=bnkbios3.spr
	$(ZXCC) gencpm -auto -display
	mv cpm3.sys cpm3bnk.sys
	rm gencpm.dat

zpmbios3:
	make biosclean
	cp optzpm.lib options.lib
	make OBJECTS=zpmbios3.spr DEST=

cpmldr.bin:	biosldrd.rel cpmldr.rel util.rel
	$(ZXCC) LINK -CPMLDRD[L100]=CPMLDR,BIOSLDRD,UTIL
	mv cpmldrd.com cpmldr.bin

cpmldr.com: biosldrc.rel cpmldr.rel util.rel
	$(ZXCC) LINK -CPMLDRC[L100]=CPMLDR,BIOSLDRC,UTIL
	mv cpmldrc.com cpmldr.com

biosldrc.rel: biosldr.z80 optcmd.lib
	cp optcmd.lib ldropts.lib	
	$(ZXCC) Z80ASM -BIOSLDR/MF
	mv biosldr.rel biosldrc.rel

biosldrd.rel: biosldr.z80 optdsk.lib
	cp optdsk.lib ldropts.lib	
	$(ZXCC) Z80ASM -BIOSLDR/MF
	mv biosldr.rel biosldrd.rel
 
bios3.spr: $(BIOSOBJS)
	$(ZXCC) LINK -bios3[OS]=$(BIOSNAMES)

bnkbios3.spr: $(BIOSOBJS)
	$(ZXCC) LINK -bnkbios3[B]=$(BIOSNAMES)

zpmbios3.spr: $(BIOSOBJS)
	$(ZXCC) LINK -zpmbios3[B]=$(BIOSNAMES)

cpm3.sys: cpm3$(DEFCPM3).sys
	cp cpm3$(DEFCPM3).sys cpm3.sys

gencpm.dat: gen$(DEFCPM3).dat
	cp gen$(DEFCPM3).dat gencpm.dat

cpmldr.sys: loader.bin cpmldr.bin
	cat loader.bin cpmldr.bin > $@

