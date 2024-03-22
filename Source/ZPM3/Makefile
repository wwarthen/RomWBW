OBJECTS = zpmldr.com zpmldr.sys cpm3.sys startzpm.com zccp.com
NODELETE = makedos.com zinstal.zpm bnkbdos3.spr resbdos3.spr
OBJECTS += setz3.com clrhist.com autotog.com
OBJECTS += cpmldr.com cpmldr.sys zinstal.zpm makedos.com gencpm.dat bnkbios3.spr bnkbdos3.spr resbdos3.spr
OTHERS = zpmldr.bin loader.bin biosldrd.rel biosldrc.rel util.rel gencpm.com
DEST = ../../Binary/ZPM3/
TOOLS =../../Tools

include $(TOOLS)/Makefile.inc

zpmldr.bin: zpm3ldr.rel biosldrd.rel util.rel
	$(ZXCC) LINK -ZPMLDRD[L100]=ZPM3LDR,BIOSLDRD,UTIL
	mv zpmldrd.com zpmldr.bin

zpmldr.com:	zpm3ldr.rel biosldrc.rel util.rel
	$(ZXCC) LINK -ZPMLDRC[L100]=ZPM3LDR,BIOSLDRC,UTIL
	mv zpmldrc.com zpmldr.com

zpmldr.sys: zpmldr.bin loader.bin
	cat loader.bin zpmldr.bin > $@

cpm3.sys: gencpm.com gencpm.dat bnkbios3.spr
	$(ZXCC) gencpm -auto -display

bnkbios3.spr: ../CPM3/zpmbios3.spr
	cp $< $@

gencpm.dat: ../CPM3/genbnk.dat
	cp $< $@

gencpm.com: ../CPM3/gencpm.com
	cp $< $@

biosldrc.rel: ../CPM3/biosldrc.rel
	cp $< $@

biosldrd.rel: ../CPM3/biosldrd.rel
	cp $< $@

util.rel: ../CPM3/util.rel
	cp $< $@

zccp.com: ../ZCCP/ccp.com
	cp $< $@

zinstal.zpm: ../ZCCP/zinstal.zpm
	cp $< $@

startzpm.com: ../ZCCP/startzpm.com
	cp $< $@

cpmldr.com: ../CPM3/cpmldr.com
	cp $< $@

cpmldr.sys: ../CPM3/cpmldr.sys
	cp $< $@
