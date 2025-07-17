#
# this makefile subsumes all the work done in Build.cmd, BuildDisk.cmd, BuildDisk.ps1
#
SYSTEMS = ../CPM22/cpm_wbw.sys ../ZSDOS/zsys_wbw.sys ../QPM/qpm_wbw.sys ../CPM3/cpmldr.sys ../ZPM3/zpmldr.sys

# OBJECTS =

HD512PREFIX =
HD1KPREFIX = hd1k_prefix.dat

# add base images used in *.def files

FDIMGS = $(wildcard fd_*.txt)
FDIMGS := $(subst fd_,,$(FDIMGS))
FDIMGS := $(addprefix fd144_,$(FDIMGS))
FDIMGS := $(FDIMGS:.txt=.img)

# $(info FDIMGS: $(FDIMGS))

HDIMGS = $(wildcard hd_*.txt)
HDIMGS := $(subst hd_,,$(HDIMGS))
HDIMGS := $(addprefix hd512_,$(HDIMGS)) $(addprefix hd1k_,$(HDIMGS))
HDIMGS := $(HDIMGS:.txt=.img)

# $(info HDIMGS: $(HDIMGS))

BASEIMGS = $(shell grep -vEh "^\#" *.def)
BASEIMGS := $(addprefix hd512_,$(BASEIMGS)) $(addprefix hd1k_,$(BASEIMGS))
BASEIMGS := $(addsuffix .img,$(BASEIMGS))

# $(info BASEIMGS: $(BASEIMGS))

DSKIMGS = $(wildcard *.def)
DSKIMGS := $(addprefix hd512_,$(DSKIMGS)) $(addprefix hd1k_,$(DSKIMGS))
DSKIMGS := $(DSKIMGS:.def=.img)

# $(info DSKIMGS: $(DSKIMGS))

OBJECTS = $(FDIMGS) $(HDIMGS) $(DSKIMGS) $(HD512PREFIX) $(HD1KPREFIX)

OTHERS = blank144 blankhd512 blankhd1k *.cat

NODELETE = $(HD512PREFIX) $(HD1KPREFIX)

DEST=../../Binary

TOOLS = ../../Tools


# $(info OBJECTS: $(OBJECTS))

include $(TOOLS)/Makefile.inc

.SHELLFLAGS = -ce

DIFFPATH = $(DIFFTO)/Binary

hd512_%.img: %.def
	@echo "Generating hd512 disk image ""$@"" using $^"; \
	files=`grep -vEh "^\s*\#" $^ | grep -vEh "^\s*$$" | tr -d '\r' | awk '{print "hd512_" $$0 ".img"}'`; \
	echo "   " $${files}; \
	cat $(HD512PREFIX) $${files} > $@

hd1k_%.img: %.def
	@echo "Generating hd1k disk image ""$@"" using $^"; \
	files=`grep -vEh "^\s*\#" $^ | grep -vEh "^\s*$$" | tr -d '\r' | awk '{print "hd1k_" $$0 ".img"}'`; \
	echo "   " $${files}; \
	cat $(HD1KPREFIX) $${files} > $@

#
# this somewhat impenetrable and fragile code is used to build each of the images
# at build time, a few variables are set (sys, fmt, type, size, d) based on the
# target to build.  first, we build an empty image using the a tr, dd pipeline.
# we then scan the d_{d}/u* directories, copying in files to user numbers
# then process the ?d_{d}.txt file, copying in those files, and finally maybe put
# an OS at the start of each image
#

FDSIZE := 1440

blank144:
	@echo Making Blank Floppy of size $(FDSIZE)k
	@LC_ALL=en_US.US-ASCII tr '\000' '\345' </dev/zero | dd of=$@ bs=1024 count=$(FDSIZE)
	@hexdump $@

HD512SIZE := 8320
HD1KSIZE := 8192

blankhd512:
	@echo Making Blank HD512 of size $(HD512SIZE)k
	@LC_ALL=en_US.US-ASCII tr '\000' '\345' </dev/zero | dd of=$@ bs=1024 count=$(HD512SIZE)
	@hexdump $@

blankhd1k:
	@echo Making Blank HD1K of size $(HD1KSIZE)k
	@LC_ALL=en_US.US-ASCII tr '\000' '\345' </dev/zero | dd of=$@ bs=1024 count=$(HD1KSIZE)
	@hexdump $@

%.img: $(SYSTEMS) blank144 blankhd512 blankhd1k # Makefile
	@if echo $@ | grep -q ^fd144_ ; then \
		fmt=wbw_fd144 ; dtype=fd ; type=fd144_ ; proto=blank144 ; \
	fi ; \
	if echo $@ | grep -q ^hd512_ ; then \
		fmt=wbw_hd512 ; dtype=hd ; type=hd512_ ; proto=blankhd512 ; \
	fi ; \
	if echo $@ | grep -q ^hd1k_ ; then \
		fmt=wbw_hd1k ; dtype=hd ; type=hd1k_ ; proto=blankhd1k ; \
	fi ; \
	d=$$(echo $(basename $@) | sed s/$$type//) ; \
	echo Generating $@ ; \
	cp $$proto $@ ; \
	if [ -f $${dtype}_$$d.txt ] ; then \
		output=` \
			grep "^\s*@" $${dtype}_$$d.txt | tr -d '\r' | while read directive ; do \
				echo $${directive#?} ; \
			done ` ; \
		eval "$$output" ; \
	fi ; \
	if [ "$$SysImage" ] ; then \
		echo copying system $$SysImage to $@ ; \
		$(BINDIR)/mkfs.cpm -f $$fmt -b $$SysImage $@ ; \
	fi ; \
	if [ "$$Label" ] ; then \
		Label=`echo "$$Label" | awk '{ print substr($$0, 1, 16) }'` ; \
		echo "Label: \"$$Label\"" ; \
		echo "\$$\$$\$$\$$\$$\$$\$$\$$\$$\$$\$$\$$\$$\$$\$$\$$\$$" | tr -d '\n' | dd conv=notrunc status=none bs=1 seek=1511 of=$@ ; \
		echo "$$Label" | tr -d '\n' | dd conv=notrunc status=none bs=1 seek=1511 of=$@; \
	fi ; \
	for u in $$(seq 0 15) ; do \
		dir=d_$$d/u$$u ; \
		if [ -d $$dir ] ; then \
			echo " " copying directory $$dir ; \
			for i in $$dir/* ; do \
				f=$$($(CASEFN) $$i) ; \
				echo "    " $$f ; \
				$(CPMCP) -f $$fmt $@ $$f $$u: ; \
			done ; \
		fi ; \
	done ; \
	if [ -f $${dtype}_$$d.txt ] ; then \
		echo " " copying files from $${dtype}_$$d.txt ; \
		grep -v "^\s*[#@]" $${dtype}_$$d.txt | tr -d '\r' | while read file user ; do \
			rf=$$($(CASEFN) $$file | sort -f) ; \
			echo "    " $$rf ; \
			if [ -z "$$rf" ] ; then \
				echo " " $$file missing ; \
				exit 1 ; \
			else \
				$(CPMCP) -f $$fmt $@ $$rf $$user ; \
			fi ; \
		done ; \
	fi ; \
	$(CPMLS) -f $$fmt -D $@ > $(@:.img=.cat)

clean::
	@rm -f *.ls

imgdiff:
	@for i in $(FDIMGS) $(HD512IMGS) $(HD512XIMGS) $(HD1KIMGS) $(HD1KXIMGS) ; do \
		echo $$i ; \
		if echo $$i | grep -q ^fd144_ ; then \
			fmt=wbw_fd144 ; \
		fi ; \
		if echo $$i | grep -q ^hd512_ ; then \
			fmt=wbw_hd512 ; \
		fi ; \
		if echo $$i | grep -q ^hd1k_ ; then \
			fmt=wbw_hd1k ; \
		fi ; \
		$(BINDIR)/cpmls -i -f $$fmt $$i > $$i.ls ; \
		$(BINDIR)/cpmls -i -f $$fmt $(DIFFPATH)/$$i > $$i.diff.ls ; \
	done \
