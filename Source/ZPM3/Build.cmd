@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\zx;%TOOLS%\cpmtools;%PATH%

set ZXBINDIR=%TOOLS%/cpm/bin/
set ZXLIBDIR=%TOOLS%/cpm/lib/
set ZXINCDIR=%TOOLS%/cpm/include/

copy ..\ZCCP\ccp.com zccp.com
copy ..\ZCCP\zinstal.zpm .
copy ..\ZCCP\startzpm.com
copy ..\CPM3\genbnk.dat .
rem copy ..\CPM3\bios3.spr .
copy ..\CPM3\bnkbios3.spr .
copy ..\CPM3\gencpm.com .
copy ..\CPM3\biosldr.rel

rem ZPM Loader
echo.
echo.
echo *** ZPM Loader ***
echo.
zx LINK -ZPMLDR[L100]=ZPM3LDR,BIOSLDR
rem pause

rem Banked CPM3
echo.
echo.
echo *** Banked ZPM3 ***
echo.
copy genbnk.dat gencpm.dat
zx gencpm -auto -display
if exist zpm3.sys del zpm3.sys
ren cpm3.sys zpm3.sys
rem pause

rem Update cpm_hd.img
echo.
echo.
echo *** Update Disk Image ***
echo.
for %%f in (
  zpmldr.com
  autotog.com
  clrhist.com
  setz3.com
  zpm3.sys
  zccp.com
  zinstal.zpm
  startzpm.com
) do call :upd_img %%f
goto :eof

:upd_img
echo   %1...
cpmrm.exe -f wbw_hd0 ../../Binary/hd_cpm3.img 0:%1
cpmcp.exe -f wbw_hd0 ../../Binary/hd_cpm3.img %1 0:%1
goto :eof