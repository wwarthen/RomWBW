OBJECTS = tastybasic.bin tbasic.com
TOOLS = ../../../Tools
OTHERS = *.com
APPDIR=../../../Binary/Apps

include $(TOOLS)/Makefile.inc

USETASM=1

tastybasic.bin: TASMFLAGS=-dROMWBW

tastybasic.com: TASMFLAGS=-dCPM

tbasic.com : tastybasic.com
	cp $< $@
	cp $$($(CASEFN) $@) $(APPDIR)