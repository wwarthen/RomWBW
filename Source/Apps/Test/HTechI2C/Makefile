OBJECTS = i2clcd.com vk16text.com rtcds7.com ledsw.com
OTHERS = *.obj *.OBJ *.asm *.hex *.lst *exec.* *.lib buildid.h
DEST = ../../../../Binary/Apps/Test
TOOLS = ../../../../Tools

USEHITECHC = 1

include $(TOOLS)/Makefile.inc

.PHONY: FORCE
FORCE:

# Regenerated every build, fails on a dirty tree.
buildid.h: FORCE
	@./gen-buildid.sh

common.lib: bfi2c.obj tick.obj

i2clcd.com: i2clcd.obj common.lib
vk16text.com: vk16text.obj common.lib
rtcds7.com: rtcds7.obj bfi2c.obj
ledsw.com: ledsw.obj bfi2c.obj

i2clcd.obj bfi2c.obj vk16text.obj rtcds7.obj ledsw.obj: bfi2c.h
i2clcd.obj vk16text.obj tick.obj: tick.h

# all programs print BUILDID, so all rebuild against a fresh one.
i2clcd.obj vk16text.obj rtcds7.obj ledsw.obj eyes.obj eyes2.obj aht10.obj ina219.obj spin.obj: buildid.h
