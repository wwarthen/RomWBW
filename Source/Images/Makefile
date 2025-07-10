#
# this makefile subsumes all the work done in Build.cmd, BuildDisk.cmd, BuildDisk.ps1
#
SYSTEMS = ../CPM22/cpm_wbw.sys ../ZSDOS/zsys_wbw.sys ../QPM/qpm_wbw.sys ../CPM3/cpmldr.sys ../ZPM3/zpmldr.sys

FDIMGS = fd144_cpm22.img fd144_zsdos.img fd144_nzcom.img \
	fd144_cpm3.img fd144_zpm3.img fd144_ws4.img fd144_qpm.img \
	fd144_z3plus.img \
	fd144_z80asm.img fd144_aztecc.img fd144_hitechc.img \
	fd144_bascomp.img fd144_fortran.img fd144_games.img \
	fd144_tpascal.img fd144_cowgol.img fd144_cobol.img
HD512IMGS = hd512_cpm22.img hd512_zsdos.img hd512_nzcom.img \
	hd512_cpm3.img hd512_zpm3.img hd512_ws4.img
HD512XIMGS = hd512_z80asm.img hd512_aztecc.img hd512_hitechc.img \
	hd512_bascomp.img hd512_fortran.img hd512_games.img \
	hd512_tpascal.img hd512_dos65.img hd512_qpm.img \
	hd512_z3plus.img hd512_infocom.img \
	hd512_cowgol.img hd512_msxroms1.img hd512_msxroms2.img \
	hd512_cobol.img  hd512_blank.img
HD1KIMGS = hd1k_cpm22.img hd1k_zsdos.img hd1k_nzcom.img \
	hd1k_cpm3.img hd1k_zpm3.img hd1k_ws4.img
HD1KXIMGS = hd1k_z80asm.img hd1k_aztecc.img hd1k_hitechc.img \
	hd1k_bascomp.img hd1k_fortran.img hd1k_games.img \
	hd1k_tpascal.img hd1k_qpm.img \
	hd1k_z3plus.img hd1k_infocom.img \
	hd1k_cowgol.img hd1k_msxroms1.img hd1k_msxroms2.img \
	hd1k_cobol.img hd1k_blank.img
HD1KXIMGS += hd1k_bp.img

HD512PREFIX =
HD1KPREFIX = hd1k_prefix.dat

OBJECTS = $(FDIMGS)
OBJECTS += $(HD512IMGS) $(HD512XIMGS) $(HD512PREFIX)
OBJECTS += $(HD1KIMGS) $(HD1KXIMGS) $(HD1KPREFIX)

# OBJECTS =

TEMP = $(wildcard *.def)
TEMP := $(addprefix hd512_,$(TEMP)) $(addprefix hd1k_,$(TEMP))
TEMP := $(TEMP:.def=.img)
OBJECTS += $(TEMP)


OTHERS = blank144 blankhd512 blankhd1k *.cat

NODELETE = $(HD512PREFIX) $(HD1KPREFIX)

DEST=../../Binary

TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

.SHELLFLAGS = -ce

DIFFPATH = $(DIFFTO)/Binary

# hd512_%.img: %.def $(HD512IMGS) $(HD512XIMGS)

hd512_%.img: %.def
	@echo "Making hd512 $^"; \
	file_list=""; \
	while read line; do \
	  line=$$(echo "$${line}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$$//') ; \
	  if [ -z "$${line}" ]; then \
	    continue;
	  fi; \
	  if [ "`expr substr "$$line" 1 1`" = "#" ]; then \
	    continue; \
	  fi; \
	  file_list="$${file_list} hd512_$${line}.img"; \
	done < $^ ; \
	echo "$${file_list}"; \
	cat $${file_list} > $@

# hd1k_%.img: %.def $(HD1KIMGS) $(HD1KXIMGS)

hd1k_%.img: %.def
	@echo "Making hd1k $^"; \
	file_list=""; \
	while read line; do \
	  line=$$(echo "$${line}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$$//') ; \
	  if [ -z "$${line}" ]; then \
	    continue;
	  fi; \
	  if [ "`expr substr "$$line" 1 1`" = "#" ]; then \
	    continue; \
	  fi; \
	  file_list="$${file_list} hd1k_$${line}.img"; \
	done < $^ ; \
	echo "$${file_list}"; \
	cat $(HD1KPREFIX) $${file_list} > $@

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
		(*qpm*) sys=../QPM/qpm_wbw.sys;; \
		(*zsdos* | *nzcom* | *dos65* | *bp*) sys=../ZSDOS/zsys_wbw.sys;; \
		(*cpm3* | *z3plus*) sys=../CPM3/cpmldr.sys;; \
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
			rf=$$($(CASEFN) $$file | sort -f) ; \
			echo "    " $$rf ; \
			if [ -z "$$rf" ] ; then \
				echo " " $$file missing ; \
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
