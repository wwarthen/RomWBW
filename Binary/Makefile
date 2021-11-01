TOOLS = ../Tools
MOREDIFF := $(shell $(TOOLS)/unix/casefn.sh *.img *.rom *.com *.eeprom)
SUBDIRS = Apps CPM3 ZPM3

include $(TOOLS)/Makefile.inc

clean::
	@rm -f *.bin *.com *.img *.rom

clobber:: clean
	@rm -f *.upd *.hex *.pdf *.log *.eeprom *.dat

.PHONEY: clean clobber
