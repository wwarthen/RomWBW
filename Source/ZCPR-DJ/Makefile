
OBJECTS= zcpr.bin

OTHERS = zcpr.rel

TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

zcpr.bin: zcpr.rel
	$(ZXCC) $(TOOLS)/cpm/bin/L80 -zcpr,zcpr.bin/n/e
