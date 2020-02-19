OBJECTS = zsdos.bin
OTHERS = zsdos.rel zsdos.err
TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

zsdos.rel: zsdos.z80
	$(ZXCC) $(CPM)/ZMAC -$< -/P

zsdos.bin: zsdos.rel
	$(ZXCC) $(CPM)/LINK -$@=$<[LD800]

