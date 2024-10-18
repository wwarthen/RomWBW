TOOLS = ../Tools
MOREDIFF := $(shell $(TOOLS)/unix/casefn.sh *.img *.rom *.com *.eeprom)
SUBDIRS = Apps CPM22 CPM3 QPM ZSDOS ZPM3 CPNET

include $(TOOLS)/Makefile.inc

clean::
	@rm -f *.bin *.com *.img *.rom *.upd *.hex *.pdf *.log *.eeprom *.dat
