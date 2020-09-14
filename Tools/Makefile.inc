#
# try to use suffix rules whenever possible in any of the lower makefiles
# in the case of exceptions, just use an explicit build rule
#
# there are also some bizarre things being done with case-sensitive sources
# make is very much case-sensitive, so we use this.  if your underlying
# filesystem is not case-preserving, forget it.
#
# .asm:  TASM sources, except somewheres it is MAC or RMAC
# .z80:  Z80ASM sources, except ZSDOS, where they are ZMAC
# .azm:  zsm sources
#
UNAME := $(shell uname)
BINDIR = $(TOOLS)/$(UNAME)

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
WINROOT = $(TREEROOT)/../RomWBW.windows
DIFFTO := $(shell if [ -d $(WINROOT) ] ; then cd $(WINROOT); pwd; fi)
DIFFPATH := $(DIFFTO)/$(RELPATH)

#
# this is a script that resolves a filename in a case-insensitive way
# to be used in diff'ing objects
#
CASEFN = $(TOOLS)/unix/casefn.sh

ZXCC=$(BINDIR)/zx
TASM=$(BINDIR)/uz80as -t hd64180
OPENSPIN=$(BINDIR)/openspin
BSTC=$(BINDIR)//bstc
CPMCP=$(BINDIR)/cpmcp

#
# directory containing cpm binaries
#
CPM=$(TOOLS)/cpm/bin

%.com: %.asm
	if [ "$(USETASM)" = 1 ] ; then \
		$(TASM) $< $@ ; \
	else \
		$(ZXCC) $(CPM)/MAC -$< -$$PO ; \
		$(ZXCC) $(CPM)/MLOAD25 -tmp.bin=$*.hex ; \
		mv tmp.bin $@ ; \
		rm -f $$($(CASEFN) $*.hex) ; \
	fi

%.hex: %.asm
	$(ZXCC) $(CPM)/MAC -$< -$$PO ; \

%.bin: %.ASM
	$(ZXCC) $(CPM)/MAC -$< -$$PO
	$(ZXCC) $(CPM)/MLOAD25 -tmp.bin=$*.hex
	mv tmp.bin $@
	rm -f $$($(CASEFN) $*.hex)

%.com: %.z80
	$(ZXCC) $(CPM)/Z80ASM -$(basename $<)/F ; \
	rm -f /tmp/casefn.cache ; \
	mv $$($(CASEFN) $@) tmp.com ; mv tmp.com $@

%.bin: %.asm
	$(TASM) $< $@

%.rel: %.asm
	$(ZXCC) $(CPM)/RMAC -$<

%.rel: %.z80
	$(ZXCC) $(CPM)/Z80ASM -$(basename $<)/MF

%.hex: %.180
	$(ZXCC) $(CPM)/SLR180 -$(basename $<)/HF

%.rel: %.azm
	$(ZXCC) $(CPM)/ZSM =$< -/L

%.bin: %.rel
	$(ZXCC) $(CPM)/LINK -$@=$<

%.rel: %.mac
	$(ZXCC) $(CPM)/M80 -=$(basename $<)

ifeq ($(UNAME), Linux)
%.eeprom: %.spin
	$(BSTC) -e -l $<
endif

.ONESHELL:

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
		( echo "building in `pwd`/$$dir" ; $(MAKE) --directory "$$dir" all ) ; \
	done
	@if [ "$(DEST)" ] ; then for file in $(filter-out $(NOCOPY),$(OBJECTS)) ; do \
		mkdir -p $(DEST) ; \
		echo copy $$file to $(DEST) ; \
		rm -f /tmp/casefn.cache ; \
		cp $$($(CASEFN) $$file) $(DEST) ; \
	done ; fi
	@if [ "$(DOCDEST)" ] ; then for file in $(DOCS) ; do \
		mkdir -p $(DOCDEST) ; \
		echo copy $$file to $(DOCDEST) ; \
		cp $$($(CASEFN) $$file) $(DOCDEST) ; \
	done ; fi

clean::
	@-rm -f $$($(CASEFN) make.out *.sym *.lst *.prn *.diff *.dump $(OTHERS) $(filter-out $(NODELETE),$(OBJECTS)))
	@for dir in $(SUBDIRS) ; do \
		( echo "cleaning in `pwd`/$$dir" ; cd "$$dir" ; make clean ) ; \
	done

clobber:: clean
	@if [ "$(DEST)" ] ; then for file in $(OBJECTS) ; do \
		rm -f $$($(CASEFN) $(DEST)/$$file) ; \
	done ; fi
	@-rm -f $$($(CASEFN) $(filter-out $(NODELETE),$(OBJECTS)))
	@for dir in $(SUBDIRS) ; do \
		( echo "clobbering in `pwd`/$$dir" ; cd "$$dir" ; make clobber ) ; \
	done

#
# this is used to verify that the unix and windows tool chains are generating
# the same objects
#
diff::
ifneq ($(DIFFTO),)
	@for dir in $(SUBDIRS) ; do \
		( echo "diff in $(HERE)/$$dir" ; cd "$$dir" ; make diff ) ; \
	done
	@for i in $(OBJECTS) $(MOREDIFF) ; do \
        sf=$$($(CASEFN) $$i) ; \
		df=$$($(CASEFN) $(DIFFPATH)/$$i) ; \
        if [ -f "$$df" -a -f "$$sf" ] ; then \
			if [ "$(VERBOSEDIFF)" ] ; then \
				echo compare $$sf and $$df ; \
			fi ; \
			if ! cmp -s $$sf $$df ; then \
				echo " " $$sf and $$df differ ; \
				if [ "$(VERBOSEDIFF)" = "2" ] ; then \
					hexdump -Cv $$sf > $$sf.dump ; \
					hexdump -Cv $$df > $$(basename $$df).dump.diff ; \
				fi \
			fi \
		else \
			if [ ! -f "$$sf" ] ; then echo $$i missing ; fi ; \
			if [ ! -f "$$df" ] ; then echo $(DIFFPATH)/$$i missing ; fi ; \
		fi ; \
    done
endif

vdiff:
	make VERBOSEDIFF=2 diff

