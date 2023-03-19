
OBJECTS= zcpr.bin zcprdemo.com

OTHERS = *.rel

TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

zcpr.bin: zcpr.rel
	$(ZXCC) L80 -zcpr,zcpr.bin/n/e

zcprdemo.com: zcprdemo.rel
	$(ZXCC) L80 -zcprdemo,zcprdemo/n/e
