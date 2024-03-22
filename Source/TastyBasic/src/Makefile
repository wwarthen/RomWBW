OBJECTS = tastybasic.bin tbasic.com
TOOLS = ../../../Tools
OTHERS = *.com
APPDIR=../../../Binary/Apps

include $(TOOLS)/Makefile.inc

# git@github.com:dimitrit/tastybasic.git; commit a86d7e7; (HEAD -> master, tag: v0.3.0) 
VER=\"v0.3.0\" 
USETASM=1

tastybasic.bin: TASMFLAGS=-dROMWBW -d"VERSION $(VER)"

tastybasic.com: TASMFLAGS=-dCPM -d"VERSION $(VER)"

tbasic.com : tastybasic.com
	cp $< $@
	cp $$($(CASEFN) $@) $(APPDIR)
