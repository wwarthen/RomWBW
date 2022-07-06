VERSIONS = \
	33t 33tbnk \
	33n 33nbnk \
	34t 34tbnk \
	34n 34nbnk \
	41tbnk 41nbnk

HD0IMG = ../../Binary/hd_bp.img
IMGFILES = $(foreach ver,$(VERSIONS),bp$(ver).img)
DISTFILES = *.zex *.rel myterm.z3t

OTHERS = zcpr33n.rel zcpr33t.rel \
	bpbio-ww.rel bpsys.dat bpsys.bak bpbio-ww.err def-ww.lib *.img

TOOLS = ../../Tools

SUBDIRS = ZCPR33
include $(TOOLS)/Makefile.inc

$(HD0IMG): $(IMGFILES)
	if [ -f $(HD0IMG) ] ; then \
		for f in $(IMGFILES) $(DISTFILES) ; do \
			$(BINDIR)/cpmrm -f wbw_hd0 $(HD0IMG) 0:$$f ; \
		done ; \
		$(CPMCP) -f wbw_hd0 $(HD0IMG) $(IMGFILES) $(DISTFILES) 0: ; \
	fi

zcpr33n.rel zcpr33t.rel:
	(cd ZCPR33 ; make)

all:: $(HD0IMG)

clean::
	@rm -f $(HD0IMG)

%.img: zcpr33n.rel zcpr33t.rel
	$(eval VER := $(subst .img,,$(subst bp,,$@)))
	cp def-ww-z$(VER).lib def-ww.lib
	rm -f bpbio-ww.rel
	$(ZXCC) ZMAC -BPBIO-WW -/P
	mv bpbio-ww.prn bp$(VER).prn
	cp bp$(VER).dat bpsys.dat
	$(ZXCC) ./bpbuild.com -bpsys.dat 0 < bpbld1.rsp
	cp bpsys.img bpsys.dat
	$(ZXCC) ./bpbuild.com -bpsys.dat 0 < bpbld2.rsp
	mv bpsys.img bp$(VER).img

