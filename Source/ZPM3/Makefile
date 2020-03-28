OBJECTS = zpmldr.com zpmldr.sys cpm3.sys startzpm.com zccp.com
ifdef REBUILD_ZPM_TOOLS
OBJECTS += setz3.com clrhist.com autotog.com
else
NODELETE = setz3.com clrhist.com autotog.com
endif
OTHERS = zpmldr.bin loader.bin biosldrd.rel biosldrc.rel gencpm.com gencpm.dat bnkbios3.spr
TOOLS =../../Tools

include $(TOOLS)/Makefile.inc

zpmldr.bin: zpm3ldr.rel biosldrd.rel
	$(ZXCC) $(CPM)/LINK -ZPMLDRD[L100]=ZPM3LDR,BIOSLDRD
	mv zpmldrd.com zpmldr.bin

zpmldr.com:	zpm3ldr.rel biosldrc.rel
	$(ZXCC) $(CPM)/LINK -ZPMLDRC[L100]=ZPM3LDR,BIOSLDRC
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

zccp.com: ../ZCCP/ccp.com
	cp $< $@

zinstal.zpm: ../ZCCP/zinstal.zpm
	cp $< $@

startzpm.com: ../ZCCP/startzpm.com
	cp $< $@

setz3.com: setz3.z80

clrhist.com: clrhist.z80

autotog.com: autotog.z80
