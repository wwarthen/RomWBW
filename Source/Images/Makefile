#
# this makefile subsumes all the work done in Build.cmd, BuildDisk.cmd, BuildDisk.ps1
#
SYSTEMS = ../CPM22/cpm_wbw.sys ../ZSDOS/zsys_wbw.sys ../CPM3/cpmldr.sys

FDIMGS = fd144_cpm22.img fd144_zsdos.img fd144_nzcom.img \
	fd144_cpm3.img fd144_zpm3.img fd144_ws4.img
HD512IMGS = hd512_cpm22.img hd512_zsdos.img hd512_nzcom.img \
	hd512_cpm3.img hd512_zpm3.img hd512_ws4.img
# HDIMGS += hd512_bp.img
HD1024IMGS = hd1024_cpm22.img hd1024_zsdos.img hd1024_nzcom.img \
	hd1024_cpm3.img hd1024_zpm3.img hd1024_ws4.img
# HD1024IMGS += hd1024_bp.img

HD512PREFIX =
HD1024PREFIX = hd1024_prefix.dat

OBJECTS = $(FDIMGS)
OBJECTS += $(HD512IMGS) hd512_combo.img $(HD512PREFIX)
OBJECTS += $(HD1024IMGS) hd1024_combo.img $(HD1024PREFIX)

OTHERS = blank144 blankhd512 blankhd1024

NODELETE = $(HD512PREFIX) $(HD1024PREFIX)

DEST=../../Binary

TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

DIFFPATH = $(DIFFTO)/Binary

hd512_combo.img: $(HD512PREFIX) $(HD512IMGS)
	cat $^ > $@

hd1024_combo.img: $(HD1024PREFIX) $(HD1024IMGS)
	cat $^ > $@

#
# this somewhat impenetrable and fragile code is used to build each of the images
# at build time, a few variables are set (sys, fmt, type, size, d) based on the
# target to build.  first, we build an empty image using the a tr, dd pipeline.
# we then scan the d_{d}/u* directories, copying in files to user numbers
# then process the d_{d}.txt file, copying in those files, and finally maybe put
# an OS at the start of each image
#

FDSIZE := 1440

blank144:
	@echo Making Blank Floppy of size $(FDSIZE)k
	@LC_ALL=en_US.US-ASCII tr '\000' '\345' </dev/zero | dd of=$@ bs=1024 count=$(FDSIZE)
	@hexdump $@

HD512SIZE := 8320
HD1024SIZE := 8192

blankhd512:
	@echo Making Blank HD512 of size $(HD512SIZE)k
	@LC_ALL=en_US.US-ASCII tr '\000' '\345' </dev/zero | dd of=$@ bs=1024 count=$(HD512SIZE)
	@hexdump $@
	
blankhd1024:
	@echo Making Blank HD1024 of size $(HD1024SIZE)k
	@LC_ALL=en_US.US-ASCII tr '\000' '\345' </dev/zero | dd of=$@ bs=1024 count=$(HD1024SIZE)
	@hexdump $@

%.img: $(SYSTEMS) blank144 blankhd512 blankhd1024 Makefile
	@sys= ; \
	case $@ in \
		(*cpm22*) sys=../CPM22/cpm_wbw.sys;; \
		(*zsdos* | *nzcom*) sys=../ZSDOS/zsys_wbw.sys;; \
		(*cpm3* | *zpm3*) sys=../CPM3/cpmldr.sys;; \
	esac ; \
	if echo $@ | grep -q ^fd144_ ; then \
		fmt=wbw_fd144 ; type=fd144_ ; proto=blank144 ; \
	fi ; \
	if echo $@ | grep -q ^hd512_ ; then \
		fmt=wbw_hd512 ; type=hd512_ ; proto=blankhd512 ; \
	fi ; \
	if echo $@ | grep -q ^hd1024_ ; then \
		fmt=wbw_hd1024 ; type=hd1024_ ; proto=blankhd1024 ; \
	fi ; \
	d=$$(echo $(basename $@) | sed s/$$type//) ; \
	echo Generating $@ ; \
	cp $$proto $@ ; \
	if [ "$$sys" ] ; then \
		echo copying system $$sys to $@ ; \
		$(BINDIR)/mkfs.cpm -f $$fmt -b $$sys $@ ; \
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
	if [ -f d_$$d.txt ] ; then \
		echo " " copying files from d_$$d.txt ; \
		grep -v ^# d_$$d.txt | tr -d '\r' | while read file user ; do \
			rf=$$($(CASEFN) $$file | sort -V) ; \
			echo "    " $$rf ; \
			if [ -z "$$rf" ] ; then \
				echo " " $$file missing ; \
			else \
				$(CPMCP) -f $$fmt $@ $$rf $$user ; \
			fi ; \
		done ; \
	fi ; \


clean::
	@rm -f *.ls

imgdiff:
	@for i in $(FDIMGS) $(HD512IMGS) $(HD1024IMGS) ; do \
		echo $$i ; \
		if echo $$i | grep -q ^fd144_ ; then \
			fmt=wbw_fd144 ; \
		fi ; \
		if echo $$i | grep -q ^hd512_ ; then \
			fmt=wbw_hd512 ; \
		fi ; \
		if echo $$i | grep -q ^hd1024_ ; then \
			fmt=wbw_hd1024 ; \
		fi ; \
		$(BINDIR)/cpmls -i -f $$fmt $$i > $$i.ls ; \
		$(BINDIR)/cpmls -i -f $$fmt $(DIFFPATH)/$$i > $$i.diff.ls ; \
	done \
