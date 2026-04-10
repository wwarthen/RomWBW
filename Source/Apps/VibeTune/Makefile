OBJECTS = vtune.com vtunezx.com vtunemsx.com
DEST = ../../../Binary/Apps
TOOLS = ../../../Tools

include $(TOOLS)/Makefile.inc

DEPS := vibetune.asm $(shell find . -name '*.inc')

vtune.com: $(DEPS)
	$(TASM) -dWBW vibetune.asm vtune.com vtune.lst

vtunezx.com: $(DEPS)
	$(TASM) -dZX vibetune.asm vtunezx.com vtunezx.lst

vtunemsx.com: $(DEPS)
	$(TASM) -dMSX vibetune.asm vtunemsx.com vtunemsx.lst

all::
	mkdir -p $(DEST)/Tunes
	cp Tunes/* $(DEST)/Tunes
