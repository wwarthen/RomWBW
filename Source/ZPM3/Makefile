OBJECTS = ZPMLDR.COM cpm3.sys zinstal.zpm startzpm.com zccp.com \
	setz3.com clrhist.com autotog.com
OTHERS = biosldr.rel gencpm.com gencpm.dat bnkbios3.spr
TOOLS =../../Tools

include $(TOOLS)/Makefile.inc

ZPMLDR.COM:	zpm3ldr.rel biosldr.rel
	$(ZXCC) $(CPM)/LINK -ZPMLDR[L100]=ZPM3LDR,BIOSLDR

cpm3.sys: gencpm.com gencpm.dat bnkbios3.spr
	$(ZXCC) gencpm -auto -display

bnkbios3.spr: ../CPM3/zpmbios3.spr
	cp $< $@

gencpm.dat: ../CPM3/genbnk.dat
	cp $< $@

gencpm.com: ../CPM3/gencpm.com
	cp $< $@

biosldr.rel: ../CPM3/biosldr.rel
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
