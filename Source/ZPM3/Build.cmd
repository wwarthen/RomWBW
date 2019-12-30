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

if not exist ../../Binary/hd_zpm3.img goto :eof

rem Update hd_zpm3.img
echo.
echo.
echo *** Update Disk Image ***
echo.
for %%f in (
  zpmldr.com
  cpmldr.com
  autotog.com
  clrhist.com
  setz3.com
  cpm3.sys
  zccp.com
  zinstal.zpm
  startzpm.com
  makedos.com
  gencpm.dat
  bnkbios3.spr
  bnkbdos3.spr
  resbdos3.spr
) do call :upd_img %%f
goto :eof

:upd_img
echo   %1...
cpmrm.exe -f wbw_hd0 ../../Binary/hd_zpm3.img 0:%1
cpmcp.exe -f wbw_hd0 ../../Binary/hd_zpm3.img %1 0:%1
goto :eof