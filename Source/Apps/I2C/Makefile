OBJECTS = i2cscan.com, rtcds7.com, i2clcd.com
DEST = ../../../Binary/Apps
TOOLS = ../../../Tools

include $(TOOLS)/Makefile.inc

DEPS1 := i2cscan.asm $(shell find . -name '*.inc')
DEPS2 := rtcds7.asm $(shell find . -name '*.inc')
DEPS3 := i2clcd.asm $(shell find . -name '*.inc')


i2cscan.com: $(DEPS1)
	$(TASM) -dWBW i2cscan.asm i2cscan.com i2cscan.lst

rtcds7.com: $(DEPS2)
	$(TASM) -dWBW rtcds7.asm rtcds7.com rtcds7.lst

i2clcd.com: $(DEPS3)
	$(TASM) -dWBW i2clcd.asm i2clcd.com i2clcd.lst


