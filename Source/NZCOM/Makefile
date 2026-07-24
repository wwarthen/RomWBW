OBJECTS = nzcom.com mkzcm.com nzblitz.com
TOOLS = ../../Tools
# DEST = ..
OTHERS = *.rel

include $(TOOLS)/Makefile.inc

%.com: %.z80
	@$(ZXCC) $(CPM)/Z80ASM -$(basename $<)/RFS
	@$(ZXCC) $(CPM)/SLRNK -$(basename $<)/n,$(basename $<)/m,/a:100,$(basename $<),b:z3lib11/s,b:syslib36/s,/e

nzblitz.com : nzblitz.z80
	@$(ZXCC) $(CPM)/Z80ASM -NZBLITZ/FS


