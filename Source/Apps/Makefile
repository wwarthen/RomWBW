OBJECTS = SysGen.com Survey.com \
	SysCopy.COM Assign.COM Format.COM Talk.COM OSLdr.COM Mode.COM RTC.COM \
	Timer.COM IntTest.COM
OTHERS = *.hex *.com
SUBDIRS = XM FDU FAT 
# Tune - left out for now
DEST = ../../Binary/Apps
TOOLS =../../Tools

include $(TOOLS)/Makefile.inc

%.COM: %.asm
	$(TASM) $< $@

