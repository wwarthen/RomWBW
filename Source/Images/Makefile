#
# this makefile subsumes all the work done in Build.cmd, BuildDisk.cmd, BuildDisk.ps1
#
SYSTEMS = ../CPM22/cpm_wbw.sys ../ZSDOS/zsys_wbw.sys ../CPM3/cpmldr.sys

FDIMGS = fd144_cpm22.img fd144_zsdos.img fd144_nzcom.img \
	fd144_cpm3.img fd144_zpm3.img fd144_ws4.img
HDIMGS = hd_cpm22.img hd_zsdos.img hd_nzcom.img \
	hd_cpm3.img hd_zpm3.img hd_ws4.img
# HDIMGS += hd_bp.img
HDNEWIMGS = hdnew_cpm22.img hdnew_zsdos.img hdnew_nzcom.img \
	hdnew_cpm3.img hdnew_zpm3.img hdnew_ws4.img
# HDNEWIMGS += hdnew_bp.img

HDPREFIX =
HDNEWPREFIX = hdnew_prefix.bin

OBJECTS = $(FDIMGS)
OBJECTS += $(HDIMGS) hd_combo.img $(HDPREFIX)
OBJECTS += $(HDNEWIMGS) hdnew_combo.img $(HDNEWPREFIX)

OTHERS = blank144 blankhd blankhdnew

NODELETE = $(HDPREFIX) $(HDNEWPREFIX)

DEST=../../Binary

TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

DIFFPATH = $(DIFFTO)/Binary

hd_combo.img: $(HDPREFIX) $(HDIMGS)
	cat $^ > $@

hdnew_combo.img: $(HDNEWPREFIX) $(HDNEWIMGS)
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
	@LC_CTYPE=en_US.US-ASCII tr '\000' '\345' </dev/zero | dd of=$@ bs=1024 count=$(FDSIZE) 2>/dev/null

HDSIZE := 8320
HDNEWSIZE := 8192

blankhd:
	@echo Making Blank Hd of size $(HDSIZE)k
	@LC_CTYPE=en_US.US-ASCII tr '\000' '\345' </dev/zero | dd of=$@ bs=1024 count=$(HDSIZE) 2>/dev/null
	
blankhdnew:
	@echo Making Blank HdNew of size $(HDNEWSIZE)k
	@LC_CTYPE=en_US.US-ASCII tr '\000' '\345' </dev/zero | dd of=$@ bs=1024 count=$(HDNEWSIZE) 2>/dev/null
	
%.img: $(SYSTEMS) blank144 blankhd blankhdnew Makefile
	@sys= ; \
	case $@ in \
		(*cpm22*) sys=../CPM22/cpm_wbw.sys;; \
		(*zsdos* | *nzcom*) sys=../ZSDOS/zsys_wbw.sys;; \
		(*cpm3* | *zpm3*) sys=../CPM3/cpmldr.sys;; \
	esac ; \
	if echo $@ | grep -q ^fd144_ ; then \
		fmt=wbw_fd144 ; type=fd144_ ; proto=blank144 ; \
	fi ; \
	if echo $@ | grep -q ^hd_ ; then \
		fmt=wbw_hd ; type=hd_ ; proto=blankhd ; \
	fi ; \
	if echo $@ | grep -q ^hdnew_ ; then \
		fmt=wbw_hdnew ; type=hdnew_ ; proto=blankhdnew ; \
	fi ; \
	d=$$(echo $(basename $@) | sed s/$$type//) ; \
	echo Generating $@ ; \
	cp $$proto $@ ; \
	if [ "$$sys" ] ; then \
		echo copying system $$sys to $@ ; \
		$(BINDIR)/mkfs.cpm -f $$fmt -b $$sys $@ ; \
	fi ; \
	# LC_CTYPE=en_US.US-ASCII echo $$mid | dd bs=1 count=4 seek=1410 conv=notrunc of=$@ ; \
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
	@for i in $(FDIMGS) $(HDIMGS) $(HDNEWIMGS) ; do \
		echo $$i ; \
		if echo $$i | grep -q ^fd144_ ; then \
			fmt=wbw_fd144 ; \
		fi ; \
		if echo $$i | grep -q ^hd_ ; then \
			fmt=wbw_hd ; \
		fi ; \
		if echo $$i | grep -q ^hdnew_ ; then \
			fmt=wbw_hdnew ; \
		fi ; \
		$(BINDIR)/cpmls -i -f $$fmt $$i > $$i.ls ; \
		$(BINDIR)/cpmls -i -f $$fmt $(DIFFPATH)/$$i > $$i.diff.ls ; \
	done \
