@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zx;%TOOLS%\cpmtools;%PATH%

set TASMTABS=%TOOLS%\tasm32

set ZXBINDIR=%TOOLS%/cpm/bin/
set ZXLIBDIR=%TOOLS%/cpm/lib/
set ZXINCDIR=%TOOLS%/cpm/include/

copy ..\ZCCP\ccp.com zccp.com
copy ..\ZCCP\zinstal.zpm .
copy ..\ZCCP\startzpm.com .
copy ..\CPM3\genbnk.dat .
copy ..\CPM3\zpmbios3.spr bnkbios3.spr
copy ..\CPM3\gencpm.com .
copy ..\CPM3\biosldrd.rel .
copy ..\CPM3\biosldrc.rel .
rem copy ..\CPM3\cpmldr.com .

rem ZPM Loader
echo.
echo.
echo *** ZPM Loader ***
echo.
zx LINK -ZPMLDRD[L100]=ZPM3LDR,BIOSLDRD
move /Y zpmldrd.com zpmldr.bin
zx LINK -ZPMLDRC[L100]=ZPM3LDR,BIOSLDRC
move /Y zpmldrc.com zpmldr.com
rem pause

rem Banked ZPM3
echo.
echo.
echo *** Banked ZPM3 ***
echo.
copy genbnk.dat gencpm.dat
zx gencpm -auto -display
rem pause

rem Loader

tasm -t80 -g3 -fFF loader.asm loader.bin loader.lst

copy /b loader.bin + zpmldr.bin zpmldr.sys
