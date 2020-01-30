#
# try to use suffix rules whenever possible in any of the lower makefiles
# in the case of exceptions, just use an explicit build rule
#
# there are also some bizarre things being done with case-sensitive sources
# make is very much case-sensitive, so we use this.  if your underlying
# filesystem is not case-preserving, forget it.
#
# .asm:  TASM sources, except ZCPR, where they are MAC.
# .ASM:  MAC or RMAC sources
# .z80:  Z80ASM sources, except ZSDOS, where they are ZMAC
# .azm:  zsm sources
#
UNAME := $(shell uname)

#
# since this file is included from below, it's handy to have an idea
# where we are relative to the tree
#
TREEROOT := $(shell cd $(TOOLS)/.. ; pwd)
HERE := $(shell pwd)
RELPATH := $(subst $(TREEROOT),,$(HERE))

#
# where's a copy of this tree for windows so we can diff binaries
#
DIFFTO := $(shell cd $(TREEROOT)/../RomWBW.windows ; pwd)
DIFFPATH := $(DIFFTO)/$(RELPATH)

#
# this is a script that resolves a filename in a case-insensitive way
# to be used in diff'ing objects
#
CASEFN = $(TOOLS)/unix/casefn.sh

ZXCC=$(TOOLS)/$(UNAME)/zx
TASM=$(TOOLS)/$(UNAME)/uz80as
OPENSPIN=$(TOOLS)/$(UNAME)/openspin
BSTC=$(TOOLS)/$(UNAME)/bstc

#
# directory containing cpm binaries
#
CPM=$(TOOLS)/cpm/bin

%.HEX: %.asm
	$(ZXCC) $(CPM)/MAC -$< -$$PO

%.HEX: %.ASM
	$(ZXCC) $(CPM)/MAC -$< -$$PO

%.BIN: %.HEX
	$(ZXCC) $(CPM)/MLOAD25 -$@=$<

%.com: %.HEX
	$(ZXCC) $(CPM)/MLOAD25 -$@=$<

%.com: %.z80
	$(ZXCC) $(CPM)/Z80ASM -$(basename $<)/F
	
%.bin: %.asm
	$(TASM) $< $@

%.rel: %.asm
	$(ZXCC) $(CPM)/RMAC -$<

%.rel: %.z80
	$(ZXCC) $(CPM)/Z80ASM -$(basename $<)/MF

%.HEX: %.180 
	$(ZXCC) $(CPM)/SLR180 -$(basename $<)/HF

%.rel: %.azm 
	$(ZXCC) $(CPM)/ZSM =$<

%.bin: %.rel
	$(ZXCC) $(CPM)/LINK -$@=$<

%.rel: %.mac
	$(ZXCC) $(CPM)/M80 -=$(basename $<)

ifeq ($(UNAME), Linux)
%.eeprom: %.spin
	$(BSTC) -e -l $<
endif

#
# darwin bstc won't run, since mac os does not do 32 bit binaries any more
# openspin ought to work
#
ifeq ($(UNAME), Darwin)
%.eeprom: %.spin
	$(OPENSPIN) -e $<
endif

#
# first target is default
#
all:: $(OBJECTS)
	@for dir in $(SUBDIRS) ; do \
		( echo "building in `pwd`/$$dir" ; cd "$$dir" ; make all ) ; \
	done

clean::
	-rm -f $$($(CASEFN) *.sym *.lst *.prn $(OTHERS) $(OBJECTS))
	@for dir in $(SUBDIRS) ; do \
		( echo "cleaning in `pwd`/$$dir" ; cd "$$dir" ; make clean ) ; \
	done

install:: all
	@for file in $(OBJECTS) ; do \
		mkdir -p $(DEST) ; \
		echo copy $$file to $(DEST) ; \
		cp $$file $(DEST) ; \
	done
	@for file in $(DOCS) ; do \
		mkdir -p $(DOCDEST) ; \
		echo copy $$file to $(DOCDEST) ; \
		cp $$file $(DOCDEST) ; \
	done
	@for dir in $(SUBDIRS) ; do \
		( echo "install in `pwd`/$$dir" ; cd "$$dir" ; make clobber ) ; \
	done

clobber: clean
	-rm -f $$($(CASEFN) $(filter-out $(NODELETE),$(OBJECTS)))
	@for dir in $(SUBDIRS) ; do \
		( echo "clobbering in `pwd`/$$dir" ; cd "$$dir" ; make clobber ) ; \
	done

diff::
	@for dir in $(SUBDIRS) ; do \
		( echo "diffing in `pwd`/$$dir" ; cd "$$dir" ; make diff ) ; \
	done
	@for i in $(OBJECTS) ; do \
        sf=$$($(CASEFN) $$i) ; df=$$($(CASEFN) $(DIFFPATH)/$$i) ; \
        echo diffing $$sf and $$df ; \
        diff $$sf $$df ; \
    done

