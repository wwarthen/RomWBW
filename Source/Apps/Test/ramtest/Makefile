OBJECTS = ramtest.com
DEST = ../../../../Binary/Apps/Test
DOCDEST = ../../../../Doc
TOOLS = ../../../../Tools
OTHERS = *.bin
include $(TOOLS)/Makefile.inc

ramtest.com: loader.bin dbgmon.bin
	cat $^ >$@

