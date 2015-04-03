@echo off

setlocal

set PATH=%PATH%;..\..\Tools\zx;..\..\Tools\cpmtools;

set ZXBINDIR=../../tools/cpm/bin/
set ZXLIBDIR=../../tools/cpm/lib/
set ZXINCDIR=../../tools/cpm/include/

rem
rem Z33 + ZSDOS11 w/ Non-banked BPBIOS
rem

copy def-z33.lib def-dx.lib
copy icfg-z33.z80 icfg-dx.z80
zx ZMAC -BPBIO-DX -/P
echo ErrorLevel: %ERRORLEVEL%

pause

if exist bp33.rel del bp33.rel
ren bpbio-dx.rel bp33.rel

if exist bpsys.img del bpsys.img
zx bpbuild -bp33.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp33.img del bp33.img
if exist bpsys.img ren bpsys.img bp33.img

if exist bpsys.img del bpsys.img
zx bpbuild -bp33x.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp33x.img del bp33x.img
if exist bpsys.img ren bpsys.img bp33x.img

if exist bpsys.img del bpsys.img
zx bpbuild -bp33t.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp33t.img del bp33t.img
if exist bpsys.img ren bpsys.img bp33t.img

if exist bpsys.img del bpsys.img
zx bpbuild -bp33n.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp33n.img del bp33n.img
if exist bpsys.img ren bpsys.img bp33n.img

REM goto :startup

rem
rem Z33 + ZSDOS11 w/ Banked BPBIOS
rem

copy def-z33bnk.lib def-dx.lib
copy icfg-z33.z80 icfg-dx.z80
zx ZMAC -BPBIO-DX -/P

if exist bp33bnk.rel del bp33bnk.rel
ren bpbio-dx.rel bp33bnk.rel

if exist bpsys.img del bpsys.img
zx bpbuild -bp33bnk.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp33bnk.img del bp33bnk.img
if exist bpsys.img ren bpsys.img bp33bnk.img

if exist bpsys.img del bpsys.img
zx bpbuild -bp33xbnk.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp33xbnk.img del bp33xbnk.img
if exist bpsys.img ren bpsys.img bp33xbnk.img

if exist bpsys.img del bpsys.img
zx bpbuild -bp33tbnk.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp33tbnk.img del bp33tbnk.img
if exist bpsys.img ren bpsys.img bp33tbnk.img

if exist bpsys.img del bpsys.img
zx bpbuild -bp33nbnk.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp33nbnk.img del bp33nbnk.img
if exist bpsys.img ren bpsys.img bp33nbnk.img

rem
rem Z34 + ZSDOS11 w/ Non-banked BPBIOS
rem

copy def-z34.lib def-dx.lib
copy icfg-z34.z80 icfg-dx.z80
zx ZMAC -BPBIO-DX -/P

if exist bp34.rel del bp34.rel
ren bpbio-dx.rel bp34.rel

if exist bpsys.img del bpsys.img
zx bpbuild -bp34.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp34.img del bp34.img
if exist bpsys.img ren bpsys.img bp34.img

if exist bpsys.img del bpsys.img
zx bpbuild -bp34x.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp34x.img del bp34x.img
if exist bpsys.img ren bpsys.img bp34x.img

if exist bpsys.img del bpsys.img
zx bpbuild -bp34t.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp34t.img del bp34t.img
if exist bpsys.img ren bpsys.img bp34t.img

if exist bpsys.img del bpsys.img
zx bpbuild -bp34n.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp34n.img del bp34n.img
if exist bpsys.img ren bpsys.img bp34n.img

rem
rem Z34 + ZSDOS11 w/ Banked BPBIOS
rem

copy def-z34bnk.lib def-dx.lib
copy icfg-z34.z80 icfg-dx.z80
zx ZMAC -BPBIO-DX -/P

if exist bp34bnk.rel del bp34bnk.rel
ren bpbio-dx.rel bp34bnk.rel

if exist bpsys.img del bpsys.img
zx bpbuild -bp34bnk.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp34bnk.img del bp34bnk.img
if exist bpsys.img ren bpsys.img bp34bnk.img

if exist bpsys.img del bpsys.img
zx bpbuild -bp34xbnk.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp34xbnk.img del bp34xbnk.img
if exist bpsys.img ren bpsys.img bp34xbnk.img

if exist bpsys.img del bpsys.img
zx bpbuild -bp34tbnk.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp34tbnk.img del bp34tbnk.img
if exist bpsys.img ren bpsys.img bp34tbnk.img

if exist bpsys.img del bpsys.img
zx bpbuild -bp34nbnk.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp34nbnk.img del bp34nbnk.img
if exist bpsys.img ren bpsys.img bp34nbnk.img

rem
rem Z41 + ZSDOS2 w/ Banked BPBIOS
rem

copy def-z41.lib def-dx.lib
copy icfg-z41.z80 icfg-dx.z80
zx ZMAC -BPBIO-DX -/P

if exist bp41.rel del bp41.rel
ren bpbio-dx.rel bp41.rel

if exist bpsys.img del bpsys.img
zx bpbuild -bp41.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp41.img del bp41.img
if exist bpsys.img ren bpsys.img bp41.img

if exist bpsys.img del bpsys.img
zx bpbuild -bp41x.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp41x.img del bp41x.img
if exist bpsys.img ren bpsys.img bp41x.img

if exist bpsys.img del bpsys.img
zx bpbuild -bp41t.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp41t.img del bp41t.img
if exist bpsys.img ren bpsys.img bp41t.img

if exist bpsys.img del bpsys.img
zx bpbuild -bp41n.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp41n.img del bp41n.img
if exist bpsys.img ren bpsys.img bp41n.img

:startup

pause

cpmrm.exe -f wbw_hd0 ../../hd0.img 0:ws*.*

cpmrm.exe -f wbw_hd0 ../../hd0.img 0:*.img
cpmcp.exe -f wbw_hd0 ../../hd0.img *.img 0:

cpmrm.exe -f wbw_hd0 ../../hd0.img 0:*.rel
cpmcp.exe -f wbw_hd0 ../../hd0.img *.rel 0:

cpmrm.exe -f wbw_hd0 ../../hd0.img 0:*.zex
cpmcp.exe -f wbw_hd0 ../../hd0.img *.zex 0:

cpmrm.exe -f wbw_hd0 ../../hd0.img 0:myterm.z3t
cpmcp.exe -f wbw_hd0 ../../hd0.img myterm.z3t 0:myterm.z3t