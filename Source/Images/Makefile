#
# this makefile subsumes all the work done in Build.cmd, BuildDisk.cmd, BuildDisk.ps1
#
SYSTEMS = ../CPM22/cpm_wbw.sys ../ZSDOS/zsys_wbw.sys ../CPM3/cpmldr.sys ../ZPM3/zpmldr.sys

FDIMGS = fd144_cpm22.img fd144_zsdos.img fd144_nzcom.img \
	fd144_cpm3.img fd144_zpm3.img fd144_ws4.img fd144_qpm.img
HD512IMGS = hd512_cpm22.img hd512_zsdos.img hd512_nzcom.img \
	hd512_cpm3.img hd512_zpm3.img hd512_ws4.img
# HDIMGS += hd512_bp.img
HD1KIMGS = hd1k_cpm22.img hd1k_zsdos.img hd1k_nzcom.img \
	hd1k_cpm3.img hd1k_zpm3.img hd1k_ws4.img
# HD1KIMGS += hd1k_bp.img

HD512PREFIX =
HD1KPREFIX = hd1k_prefix.dat

OBJECTS = $(FDIMGS)
OBJECTS += $(HD512IMGS) hd512_combo.img  hd512_dos65.img hd512_qpm.img$(HD512PREFIX)
OBJECTS += $(HD1KIMGS) hd1k_combo.img hd1k_qpm.img $(HD1KPREFIX)

OTHERS = blank144 blankhd512 blankhd1k

NODELETE = $(HD512PREFIX) $(HD1KPREFIX)

DEST=../../Binary

TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

.SHELLFLAGS = -ce

DIFFPATH = $(DIFFTO)/Binary

hd512_combo.img: $(HD512PREFIX) $(HD512IMGS)
	cat $^ > $@

hd1k_combo.img: $(HD1KPREFIX) $(HD1KIMGS)
	cat $^ > $@

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

%.img: $(SYSTEMS) blank144 blankhd512 blankhd1k Makefile
	@sys= ; \
	case $@ in \
		(*cpm22*) sys=../CPM22/cpm_wbw.sys;; \
		(*qpm*) sys=d_qpm/u0/qpm.sys;; \
		(*zsdos* | *nzcom* | *dos65*) sys=../ZSDOS/zsys_wbw.sys;; \
		(*cpm3*) sys=../CPM3/cpmldr.sys;; \
		(*zpm3*) sys=../ZPM3/zpmldr.sys;; \
	esac ; \
	if echo $@ | grep -q ^fd144_ ; then \
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
	echo $${dtype}_$$d.txt ; \
	if [ -f $${dtype}_$$d.txt ] ; then \
		echo " " copying files from $${dtype}_$$d.txt ; \
		grep -v ^# $${dtype}_$$d.txt | tr -d '\r' | while read file user ; do \
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
	@for i in $(FDIMGS) $(HD512IMGS) $(HD1KIMGS) ; do \
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
