OBJECTS = Tune.com Tunezx.com Tunemsx.com
DEST = ../../../Binary/Apps
TOOLS = ../../../Tools

include $(TOOLS)/Makefile.inc

DEPS := Tune.asm $(shell find . -name '*.inc')

Tune.com: $(DEPS)
	$(TASM) -dWBW Tune.asm Tune.com

Tunezx.com: $(DEPS)
	$(TASM) -dZX Tune.asm Tunezx.com

Tunemsx.com: $(DEPS)
	$(TASM) -dMSX Tune.asm Tunemsx.com

all::
	mkdir -p $(DEST)/Tunes
	cp Tunes/* $(DEST)/Tunes
