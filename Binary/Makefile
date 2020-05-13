TOOLS = ../Tools
MOREDIFF := $(shell $(TOOLS)/unix/casefn.sh *.img *.rom *.com *.eeprom)
SUBDIRS = Apps CPM3 ZPM3

include $(TOOLS)/Makefile.inc

clobber::
	@rm -f *.bin *.com *.img *.rom *.pdf *.log *.eeprom
