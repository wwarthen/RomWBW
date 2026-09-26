OBJECTS = rndtest.com eeblank.com
OTHERS = *.obj *.OBJ *.asm *.hex *.lst *exec.*
DEST = ../../../../Binary/Apps/Test
TOOLS = ../../../../Tools

USEHITECHC = 1

include $(TOOLS)/Makefile.inc

rndtest.com: rndtest.obj hbio.obj
eeblank.com: eeblank.obj hbio.obj
rndtest.obj eeblank.obj hbio.obj: hbio.h
