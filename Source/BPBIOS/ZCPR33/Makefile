OBJECTS = zcpr33.rel
OTHERS = z3base.lib *.prn *.rel
TOOLS = ../../../Tools
DEST = ..

include $(TOOLS)/Makefile.inc

DIFFPATH = $(DIFFTO)/Source/BPBIOS

zcpr33.rel: ../z3base.lib
	cp ../z3base.lib z3base.lib
	$(ZXCC) ZMAC -zcpr33.z80 -/P
	rm z3base.lib
