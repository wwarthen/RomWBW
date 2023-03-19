
OBJECTS = zcpr.bin bdloc.com

OTHERS = *.hex

TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

zcpr.bin: zcpr.asm
	$(ZXCC) MAC -$< -$$PO
	$(ZXCC) MLOAD25 -$@=zcpr.hex

