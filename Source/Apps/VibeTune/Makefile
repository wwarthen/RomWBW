OBJECTS = vibetune.com vibetunezx.com vibetunemsx.com
DEST = ../../../Binary/Apps
TOOLS = ../../../Tools

include $(TOOLS)/Makefile.inc

DEPS := vibetune.asm $(shell find . -name '*.inc')

vibetune.com: $(DEPS)
	$(TASM) -dWBW vibetune.asm vibetune.com vibetune.lst

vibetunezx.com: $(DEPS)
	$(TASM) -dZX vibetune.asm vibetunezx.com vibetunezx.lst

vibetunemsx.com: $(DEPS)
	$(TASM) -dMSX vibetune.asm vibetunemsx.com vibetunemsx.lst

all::
	mkdir -p $(DEST)/Tunes
	cp Tunes/* $(DEST)/Tunes
