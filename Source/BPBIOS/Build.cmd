@echo off
setlocal

pushd ZCPR33 && call Build || exit /b & popd

set PATH=%PATH%;..\..\Tools\zx;..\..\Tools\cpmtools;

set ZXBINDIR=../../tools/cpm/bin/
set ZXLIBDIR=../../tools/cpm/lib/
set ZXINCDIR=../../tools/cpm/include/

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

rem pause

rem cpmrm.exe -f wbw_hd0 ../../Binary/hd_bp.img 0:ws*.*
rem 
rem cpmrm.exe -f wbw_hd0 ../../Binary/hd_bp.img 0:*.img
rem cpmcp.exe -f wbw_hd0 ../../Binary/hd_bp.img *.img 0:
rem 
rem cpmrm.exe -f wbw_hd0 ../../Binary/hd_bp.img 0:*.rel
rem cpmcp.exe -f wbw_hd0 ../../Binary/hd_bp.img *.rel 0:
rem 
rem rem cpmrm.exe -f wbw_hd0 ../../Binary/hd_bp.img 0:*.dat
rem rem cpmcp.exe -f wbw_hd0 ../../Binary/hd_bp.img *.dat 0:
rem 
rem cpmrm.exe -f wbw_hd0 ../../Binary/hd_bp.img 0:*.zex
rem cpmcp.exe -f wbw_hd0 ../../Binary/hd_bp.img *.zex 0:
rem 
rem cpmrm.exe -f wbw_hd0 ../../Binary/hd_bp.img 0:myterm.z3t
rem cpmcp.exe -f wbw_hd0 ../../Binary/hd_bp.img myterm.z3t 0:myterm.z3t

goto :eof

:makebp

set VER=%1
echo.
echo Building BPBIOS Variant "%VER%"...
echo.

copy def-ww-z%VER%.lib def-ww.lib || exit /b
rem if exist bpbio-ww.rel del bpbio-ww.rel || exit /b
zx ZMAC -BPBIO-WW -/P || exit /b
if exist bp%VER%.prn del bp%VER%.prn || exit /b
ren bpbio-ww.prn bp%VER%.prn || exit /b
if exist bp%VER%.err del bp%VER%.err || exit /b
ren bpbio-ww.err bp%VER%.err || exit /b
copy bpbio-ww.rel bp%VER%.rel || exit /b

rem pause

rem BPBUILD attempts to rename bpsys.img -> bpsys.bak
rem while is is still open.  Real CP/M does not care,
rem but zx fails due to host OS.  Below, a temp file
rem is used to avoid the problematic rename.

if exist bpsys.img del bpsys.img || exit /b
if exist bpsys.tmp del bpsys.tmp || exit /b
copy bp%VER%.dat bpsys.tmp || exit /b
rem bpsys.tmp -> bpsys.img
zx bpbuild -bpsys.tmp <bpbld1.rsp || exit /b
if exist bpsys.tmp del bpsys.tmp || exit /b
copy bpsys.img bpsys.tmp || exit /b
rem bpsys.tmp -> bpsys.img
zx bpbuild -bpsys.tmp <bpbld2.rsp || exit /b
if exist bp%VER%.img del bp%VER%.img || exit /b
if exist bpsys.img ren bpsys.img bp%VER%.img || exit /b

rem pause

goto :eof