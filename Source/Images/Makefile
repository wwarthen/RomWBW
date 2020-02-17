#
# this makefile subsumes all the work done in Build.cmd, Build{Hd,Fd}.*
#
SYSTEMS = cpm_wbw.sys cpm_una.sys zsys_wbw.sys zsys_una.sys
FDIMGS = fd_cpm22.img fd_zsdos.img fd_nzcom.img fd_cpm3.img fd_zpm3.img fd_ws4.img
HDIMGS = hd_cpm22.img hd_zsdos.img hd_nzcom.img hd_cpm3.img hd_zpm3.img hd_ws4.img
OBJECTS = $(FDIMGS) $(HDIMGS)
OTHERS = $(SYSTEMS)

DEST=../../Binary

TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

#
# create the os's, which are the bootloader, ccp, bdos and bios
#
cpm_wbw.sys:
	cat $$($(CASEFN) \
		../BL/bl.bin \
		../CPM22/os2ccp.bin ../CPM22/OS3BDOS.BIN \
		../CBIOS/cbios_wbw.bin) > cpm_wbw.sys

cpm_una.sys:
	cat $$($(CASEFN) \
		../BL/bl.bin \
		../CPM22/os2ccp.bin ../CPM22/OS3BDOS.BIN \
		../CBIOS/cbios_una.bin) > cpm_una.sys

zsys_wbw.sys:
	cat $$($(CASEFN) \
		../BL/bl.bin \
		../ZCPR-DJ/zcpr.bin ../ZSDOS/ZSDOS.BIN \
		../CBIOS/cbios_wbw.bin) > zsys_wbw.sys

zsys_una.sys:
	cat $$($(CASEFN) \
		../BL/bl.bin \
		../ZCPR-DJ/zcpr.bin ../ZSDOS/ZSDOS.BIN \
		../CBIOS/cbios_una.bin) > zsys_una.sys

HDSIZE=$(shell expr 128 '*' 65)

#
# this somewhat impenetrable and fragile code is used to build each of the images
# at build time, a few variables are set (sys, fmt, type, size, d) based on the
# target to build.  first, we build an empty image using the a tr, dd pipeline.
# we then scan the d_{d}/u* directories, copying in files to user numbers
# then process the d_{d}.txt file, copying in those files, and finally maybe put
# an OS at the start of each image
#
%.img:: $(SYSTEMS)
	sys= ; \
	case $@ in (*cpm22*) sys=cpm_wbw.sys;; (*zsdos* | *nzcom) sys=zsys_wbw.sys;; esac ; \
	if echo $@ | grep -q ^f ; then \
		fmt=wbw_fd144 ; type=fd_ ; size=1440 ; \
	else \
		fmt=wbw_hd0 ; type=hd_ ; size=$(HDSIZE) ; \
	fi ; \
	d=$$(echo $(basename $@) | sed s/$$type//) ; \
	echo $@ $$d $$type $$size $$fmt $$sys ; \
	LANG=en_US.US-ASCII tr '\000' '\345' </dev/zero | dd of=$@ bs=1024 count=$$size ; \
	for u in $$(seq 0 15) ; do \
		dir=d_$$d/u$$u ; \
		if [ -d $$dir ] ; then \
			echo $(CPMCP) -f $$fmt $@ $$($(CASEFN) $$dir/*.*) $$u: ; \
			$(CPMCP) -f $$fmt $@ $$($(CASEFN) $$dir/*.*) $$u: ; \
		fi ; \
	done ; \
	if [ -f d_$$d.txt ] ; then \
		grep -v ^# d_$$d.txt | while read file user ; do \
			echo $$file $$user ; \
			echo $(CPMCP) -f $$fmt $@ $$($(CASEFN) $$file) $$user ; \
			$(CPMCP) -f $$fmt $@ $$($(CASEFN) $$file) $$user ; \
		done ; \
	fi ; \
	if [ "$$sys" ] ; then \
		echo copying system $$sys to $@ ; \
		dd if=$$sys of=$@ conv=notrunc ; \
	fi

install::
