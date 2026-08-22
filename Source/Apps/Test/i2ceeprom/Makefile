OBJECTS = rndtest.com
OTHERS = *.obj *.OBJ *.asm *.hex *.lst *exec.*
DEST = ../../../../Binary/Apps/Test
TOOLS = ../../../../Tools

USEHITECHC = 1

include $(TOOLS)/Makefile.inc

rndtest.com: rndtest.obj hbio.obj
rndtest.obj hbio.obj: hbio.h
