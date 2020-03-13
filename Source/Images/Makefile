#
# this makefile subsumes all the work done in Build.cmd, Build{Hd,Fd}.*
#
SYSTEMS = ../CPM22/cpm_wbw.sys ../ZSDOS/zsys_wbw.sys ../CPM3/cpmldr.sys

FDIMGS = fd_cpm22.img fd_zsdos.img fd_nzcom.img \
	fd_cpm3.img fd_zpm3.img fd_ws4.img
HDIMGS = hd_cpm22.img hd_zsdos.img hd_nzcom.img \
	hd_cpm3.img hd_zpm3.img hd_ws4.img
# HDIMGS += hd_bp.img

OBJECTS = $(FDIMGS) $(HDIMGS) hd_combo.img
OTHERS = blank144 blankhd

DEST=../../Binary

TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

DIFFPATH = $(DIFFTO)/Binary

hd_combo.img:	$(HDIMGS)
	cat $(HDIMGS) > $@

#
# this somewhat impenetrable and fragile code is used to build each of the images
# at build time, a few variables are set (sys, fmt, type, size, d) based on the
# target to build.  first, we build an empty image using the a tr, dd pipeline.
# we then scan the d_{d}/u* directories, copying in files to user numbers
# then process the d_{d}.txt file, copying in those files, and finally maybe put
# an OS at the start of each image
#
blank144:
	@echo Making Blank Floppy of size 1440k
	@LANG=en_US.US-ASCII tr '\000' '\345' </dev/zero | dd of=$@ bs=1024 count=1440 2>/dev/null

HDSIZE := $(shell expr 128 '*' 65)

blankhd:
	@echo Making Blank Hd of size $(HDSIZE)k
	@LANG=en_US.US-ASCII tr '\000' '\345' </dev/zero | dd of=$@ bs=1024 count=$(HDSIZE) 2>/dev/null

%.img: $(SYSTEMS) blank144 blankhd Makefile
	@sys= ; \
	case $@ in \
		(*cpm22*) sys=../CPM22/cpm_wbw.sys;; \
		(*zsdos* | *nzcom*) sys=../ZSDOS/zsys_wbw.sys;; \
		(*cpm3* | *zpm3*) sys=../CPM3/cpmldr.sys;; \
	esac ; \
	if echo $@ | grep -q ^f ; then \
		fmt=wbw_fd144 ; type=fd_ ; proto=blank144 ; \
	else \
		fmt=wbw_hd0 ; type=hd_ ; proto=blankhd ; \
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
	@for i in $(FDIMGS) $(HDIMGS) ; do \
		echo $$i ; \
		if echo $$i | grep -q ^f ; then \
			fmt=wbw_fd144 ; \
		else \
			fmt=wbw_hd0 ; \
		fi ; \
		$(BINDIR)/cpmls -i -f $$fmt $$i > $$i.ls ; \
		$(BINDIR)/cpmls -i -f $$fmt $(DIFFPATH)/$$i > $$i.diff.ls ; \
	done \
