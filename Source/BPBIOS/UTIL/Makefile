OBJECTS = bpbuild.com bpcnfg.com bpswap.com bpsysgen.com confz4.com hashini.com \
	ldsys.com showhd.com sizeram.com zscfg2.com
TOOLS = ../../../Tools
# DEST = ..
OTHERS = *.rel

include $(TOOLS)/Makefile.inc

%.rel: %.z80
	@$(ZXCC) $(CPM)/Z80ASM -$(basename $<)/RFS

bpbuild.com : bpbuild.rel
	$(ZXCC) $(CPM)/SLRNK -bpbuild/n,/a:100,/d:23e0,bpbuild,b:slink0,b:vlibs/s,b:z3libs/s,b:syslibs/s,/e

bpcnfg.com : bpcnfg.rel
	$(ZXCC) $(CPM)/SLRNK -bpcnfg/n,/a:100,/d:3a55,bpcnfg,b:vlibs/s,b:z3libs/s,b:syslibs/s,/e

bpswap.com : bpswap.rel
	$(ZXCC) $(CPM)/SLRNK -bpswap/n,/a:100,/d:0854,bpswap,b:vlibs/s,b:z3libs/s,b:syslibs/s,/e

bpsysgen.com : bpsysgen.rel
	$(ZXCC) $(CPM)/SLRNK -bpsysgen/n,/a:100,/d:08cd,bpsysgen,b:z3libs/s,b:syslibs/s,/e

confz4.com : confz4.rel
	$(ZXCC) $(CPM)/SLRNK -confz4/n,/a:100,/d:080a,confz4,b:z3libs/s,b:syslibs/s,/e

hashini.com : hashini.rel
	$(ZXCC) $(CPM)/SLRNK -hashini/n,/a:100,/d:09e5,hashini,b:z3libs/s,b:syslibs/s,/e

ldsys.com : ldsys.rel
	$(ZXCC) $(CPM)/SLRNK -ldsys/n,/a:100,/d:0cf8,ldsys,b:vlibs/s,b:z3libs/s,b:syslibs/s,/e

showhd.com : showhd.rel
	$(ZXCC) $(CPM)/SLRNK -showhd/n,/a:100,/d:064d,showhd,b:syslibs/s,/e

sizeram.com : sizeram.rel
	$(ZXCC) $(CPM)/SLRNK -sizeram/n,/a:100,/d:0750,sizeram,b:vlibs/s,b:z3libs/s,b:syslibs/s,/e

zscfg2.com : zscfg2.rel
	$(ZXCC) $(CPM)/SLRNK -zscfg2/n,/a:100,/d:145e,zscfg2,b:vlibs/s,b:z3libs/s,b:syslibs/s,/e
