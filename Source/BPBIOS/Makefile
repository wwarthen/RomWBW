VERSIONS = \
	33t 33tbnk \
	33n 33nbnk \
	34t 34tbnk \
	34n 34nbnk \
	41tbnk 41nbnk

HD0IMG = ../../Binary/hd0.img
IMGFILES = $(foreach ver,$(VERSIONS),bp$(ver).img)
DISTFILES = *.zex *.rel myterm.z3t

OTHERS = zcpr33n.rel zcpr33t.rel \
	bpbio-ww.rel bpsys.dat bpsys.bak bpbio-ww.err def-ww.lib

TOOLS = ../../Tools

SUBDIRS = ZCPR33
include $(TOOLS)/Makefile.inc

$(HD0IMG): $(IMGFILES)
	$(CPMCP) -f wbw_hd0 $(HD0IMG) $(IMGFILES) $(DISTFILES) 0:

zcpr33n.rel zcpr33t.rel:
	(cd ZCPR33 ; make install)

all:: $(HD0IMG)

clobber::
	rm -f $(HD0IMG)

%.img: zcpr33n.rel zcpr33t.rel
	$(eval VER := $(subst .img,,$(subst bp,,$@)))
	cp def-ww-z$(VER).lib def-ww.lib
	rm -f bpbio-ww.rel
	$(ZXCC) $(CPM)/ZMAC -BPBIO-WW -/P
	mv bpbio-ww.prn bp$(VER).prn
	cp bp$(VER).dat bpsys.dat
	$(ZXCC) ./bpbuild.com -bpsys.dat 0 < bpbld1.rsp
	cp bpsys.img bpsys.dat
	$(ZXCC) ./bpbuild.com -bpsys.dat 0 < bpbld2.rsp
	mv bpsys.img bp$(VER).img

# 
# 
# rem cpmrm.exe -f wbw_hd0 ../../Binary/hd0.img 0:*.dat
# rem cpmcp.exe -f wbw_hd0 ../../Binary/hd0.img *.dat 0:
# 
# cpmrm.exe -f wbw_hd0 ../../Binary/hd0.img 0:*.zex
# 
# cpmrm.exe -f wbw_hd0 ../../Binary/hd0.img 0:myterm.z3t
# 
# goto :eof
# 
# :makebp
# 
# set VER=%1
# echo.
# echo Building BPBIOS Variant "%VER%"...
# echo.
# 
# copy def-ww-z%VER%.lib def-ww.lib
# rem if exist bpbio-ww.rel del bpbio-ww.rel
# zx ZMAC -BPBIO-WW -/P
# if exist bp%VER%.prn del bp%VER%.prn
# ren bpbio-ww.prn bp%VER%.prn
# 
# rem pause
# 
# rem BPBUILD attempts to rename bpsys.img -> bpsys.bak
# rem while is is still open.  Real CP/M does not care,
# rem but zx fails due to host OS.  Below, a temp file
# rem is used to avoid the problematic rename.
# 
# if exist bpsys.img del bpsys.img
# if exist bpsys.tmp del bpsys.tmp
# copy bp%VER%.dat bpsys.tmp
# rem bpsys.tmp -> bpsys.img
# zx bpbuild -bpsys.tmp <bpbld1.rsp
# if exist bpsys.tmp del bpsys.tmp
# copy bpsys.img bpsys.tmp
# rem bpsys.tmp -> bpsys.img
# zx bpbuild -bpsys.tmp <bpbld2.rsp
# if exist bp%VER%.img del bp%VER%.img
# if exist bpsys.img ren bpsys.img bp%VER%.img
# 
# rem pause
# 
# goto :eof@echo off
# setlocal
# 
# if exist *.tmp del *.tmp
# if exist *.prn del *.prn
# if exist *.err del *.err
# if exist *.img del *.img
# if exist bp*.rel del bp*.rel
# if exist zcpr33*.rel del zcpr33*.rel
# if exist *.bak del *.bak
# 
# setlocal & cd ZCPR33 && call Clean.cmd & endlocal
