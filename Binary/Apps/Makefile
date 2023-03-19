TOOLS = ../../Tools
MOREDIFF := $(shell $(TOOLS)/unix/casefn.sh *.com)
SUBDIRS = Test

include $(TOOLS)/Makefile.inc

all::
	mkdir -p Tunes

clean::
	@rm -f *.bin *.com *.img *.rom *.pdf *.log *.eeprom *.ovr *.hlp *.doc *.COM *.BIN Tunes/*.mym Tunes/*.pt? Tunes/*.vgm
