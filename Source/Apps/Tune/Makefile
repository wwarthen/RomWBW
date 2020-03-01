OBJECTS = Tune.com
DEST = ../../../Binary/Apps
TOOLS = ../../../Tools

include $(TOOLS)/Makefile.inc

Tune.com: Tune.asm
	$(TASM) Tune.asm Tune.com

all::
	mkdir -p $(DEST)/Tunes
	cp Tunes/* $(DEST)/Tunes
