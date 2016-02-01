@echo off

setlocal

set PATH=%PATH%;..\..\Tools\zx;..\..\Tools\cpmtools;

set ZXBINDIR=../../tools/cpm/bin/
set ZXLIBDIR=../../tools/cpm/lib/
set ZXINCDIR=../../tools/cpm/include/

pushd ZCPR33 && call Build.cmd && popd

pause

call :makebp 33t
call :makebp 33tbnk
call :makebp 33n
call :makebp 33nbnk

call :makebp 34t
call :makebp 34tbnk
call :makebp 34n
call :makebp 34nbnk

call :makebp 41tbnk
call :makebp 41nbnk

pause

cpmrm.exe -f wbw_hd0 ../../Output/hd0.img 0:ws*.*

cpmrm.exe -f wbw_hd0 ../../Output/hd0.img 0:*.img
cpmcp.exe -f wbw_hd0 ../../Output/hd0.img *.img 0:

cpmrm.exe -f wbw_hd0 ../../Output/hd0.img 0:*.rel
cpmcp.exe -f wbw_hd0 ../../Output/hd0.img *.rel 0:

rem cpmrm.exe -f wbw_hd0 ../../Output/hd0.img 0:*.dat
rem cpmcp.exe -f wbw_hd0 ../../Output/hd0.img *.dat 0:

cpmrm.exe -f wbw_hd0 ../../Output/hd0.img 0:*.zex
cpmcp.exe -f wbw_hd0 ../../Output/hd0.img *.zex 0:

cpmrm.exe -f wbw_hd0 ../../Output/hd0.img 0:myterm.z3t
cpmcp.exe -f wbw_hd0 ../../Output/hd0.img myterm.z3t 0:myterm.z3t

goto :eof

:makebp

set VER=%1
echo.
echo Building BPBIOS Variant "%VER%"...
echo.

copy def-ww-z%VER%.lib def-ww.lib
if exist bpbio-ww.rel del bpbio-ww.rel
zx ZMAC -BPBIO-WW -/P
if exist bp%VER%.prn del bp%VER%.prn
ren bpbio-ww.prn bp%VER%.prn

rem pause

if exist bpsys.img del bpsys.img
zx bpbuild -bp%VER%.dat <bpbld1.rsp
if exist bpsys.$$$ del bpsys.$$$
ren bpsys.img bpsys.$$$
zx bpbuild -bpsys.$$$ <bpbld2.rsp
if exist bpsys.$$$ del bpsys.$$$
if exist bp%VER%.img del bp%VER%.img
if exist bpsys.img ren bpsys.img bp%VER%.img

rem pause

goto :eof
