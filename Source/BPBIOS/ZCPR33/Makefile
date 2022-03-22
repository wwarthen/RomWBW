OBJECTS = zcpr33n.rel zcpr33t.rel
OTHERS = z3basen.lib z3baset.lib
TOOLS = ../../../Tools
DEST = ..

include $(TOOLS)/Makefile.inc

DIFFPATH = $(DIFFTO)/Source/BPBIOS

zcpr33t.rel: ../z3baset.lib
	cp ../z3baset.lib z3baset.lib
	$(ZXCC) ZMAC -zcpr33t.z80 -/P
	rm z3baset.lib

zcpr33n.rel: ../z3basen.lib
	cp ../z3basen.lib z3basen.lib
	$(ZXCC) ZMAC -zcpr33n.z80 -/P
	rm z3basen.lib
