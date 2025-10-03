OBJECTS = msx-ldr.com
DEST = ../../Binary
TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

msx-ldr.com: msx-ldr.asm 
	$(TASM) $< $@ msx-ldr.lst
	cp msx-ldr.com $(DEST)/msx-ldr.com
