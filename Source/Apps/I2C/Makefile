OBJECTS = I2CSCAN.COM 
DEST = ../../../Binary/Apps
TOOLS = ../../../Tools

include $(TOOLS)/Makefile.inc

DEPS := I2CSCAN.ASM $(shell find . -name '*.inc')

I2CSCAN.COM: $(DEPS)
	$(TASM) -dWBW I2CSCAN.ASM I2CSCAN.COM I2CSCAN.LST


