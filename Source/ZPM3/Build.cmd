@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\zx;%TOOLS%\cpmtools;%PATH%

set ZXBINDIR=%TOOLS%/cpm/bin/
set ZXLIBDIR=%TOOLS%/cpm/lib/
set ZXINCDIR=%TOOLS%/cpm/include/

copy ..\ZCCP\ccp.com zccp.com
copy ..\ZCCP\zinstal.zpm .
copy ..\ZCCP\startzpm.com .
copy ..\CPM3\genbnk.dat .
copy ..\CPM3\zpmbios3.spr bnkbios3.spr
copy ..\CPM3\gencpm.com .
copy ..\CPM3\biosldr.rel .
copy ..\CPM3\cpmldr.com .

rem ZPM Loader
echo.
echo.
echo *** ZPM Loader ***
echo.
zx LINK -ZPMLDR[L100]=ZPM3LDR,BIOSLDR
rem pause

rem Banked ZPM3
echo.
echo.
echo *** Banked ZPM3 ***
echo.
copy genbnk.dat gencpm.dat
zx gencpm -auto -display
rem pause
