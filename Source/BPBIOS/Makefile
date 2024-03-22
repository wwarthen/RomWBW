VERSIONS = \
	33 33bnk \
	33 33bnk \
	34 34bnk \
	34 34bnk \
	41bnk

IMGFILES = $(foreach ver,$(VERSIONS),bp$(ver).img)
DISTFILES = *.zex *.rel myterm.z3t

OTHERS = zcpr33.rel bp*.prn bp*.rel \
	bpbio-ww.rel bpsys.dat bpsys.bak bpbio-ww.err def-ww.lib bp*.img

TOOLS = ../../Tools

SUBDIRS = ZCPR33
include $(TOOLS)/Makefile.inc

zcpr33.rel:
	(cd ZCPR33 ; make)

all:: $(IMGFILES)

# clean::
# 	$(MAKE) --directory ZCPR3 clean

%.img: zcpr33.rel
	$(eval VER := $(subst .img,,$(subst bp,,$@)))
	cp def-ww-z$(VER).lib def-ww.lib
	rm -f bpbio-ww.rel
	$(ZXCC) ZMAC -BPBIO-WW -/P
	mv bpbio-ww.prn bp$(VER).prn
	if [ -f bpbio-ww.err ] ; then mv bpbio-ww.err bp$(VER).err; fi
	mv bpbio-ww.rel bp$(VER).rel
	cp bp$(VER).dat bpsys.dat
	$(ZXCC) ./bpbuild.com -bpsys.dat 0 < bpbld1.rsp
	cp bpsys.img bpsys.dat
	$(ZXCC) ./bpbuild.com -bpsys.dat 0 < bpbld2.rsp
	mv bpsys.img bp$(VER).img

