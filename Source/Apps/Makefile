OBJECTS = SysGen.com Survey.com \
	SysCopy.COM Assign.COM Format.COM Talk.COM OSLdr.COM Mode.COM RTC.COM \
	Timer.COM IntTest.COM
OTHERS = *.hex *.com
SUBDIRS = XM FDU Tune FAT
DEST = ../../Binary/Apps
TOOLS =../../Tools
RELPATH = Source/Apps

include $(TOOLS)/Makefile.inc

%.COM: %.asm
	$(TASM) $< $@

foo:
	echo treeroot: $(TREEROOT) here: $(HERE) relpath: $(RELPATH1)

#diff::
#	-for i in $(OBJECTS) ; do \
#		sf=$$($(CASEFN) $$i) ; df=$$($(CASEFN) $(DIFFTO)/$(RELPATH)/$$i) ; \
#		echo diffing $$sf and $$df ; \
#		diff $$sf $$df ; \
#	done
