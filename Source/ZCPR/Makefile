
OBJECTS = zcpr.bin bdloc.com

OTHERS = *.hex

TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

zcpr.bin: zcpr.asm
	$(ZXCC) $(CPM)/MAC -$< -$$PO
	$(ZXCC) $(CPM)/MLOAD25 -$@=zcpr.hex

