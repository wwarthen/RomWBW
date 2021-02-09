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
copy ..\CPM3\util.rel .
copy ..\CPM3\biosldrd.rel .
copy ..\CPM3\biosldrc.rel .
copy ..\CPM3\cpmldr.com .
copy ..\CPM3\cpmldr.sys .

rem ZPM Loader
echo.
echo.
echo *** ZPM Loader ***
echo.
zx LINK -ZPMLDRD[L100]=ZPM3LDR,BIOSLDRD,UTIL
move /Y zpmldrd.com zpmldr.bin
zx LINK -ZPMLDRC[L100]=ZPM3LDR,BIOSLDRC,UTIL
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

rem ZPM3 Tools
zx Z80ASM -clrhist/F
zx Z80ASM -setz3/F
zx Z80ASM -autotog/F

rem Loader

tasm -t80 -g3 -fFF loader.asm loader.bin loader.lst

copy /b loader.bin + zpmldr.bin zpmldr.sys

rem Copy OS files to Binary directory

copy zpmldr.com ..\..\Binary\ZPM3
copy zpmldr.sys ..\..\Binary\ZPM3
copy cpmldr.com ..\..\Binary\ZPM3
copy cpmldr.sys ..\..\Binary\ZPM3
copy autotog.com ..\..\Binary\ZPM3
copy clrhist.com ..\..\Binary\ZPM3
copy setz3.com ..\..\Binary\ZPM3
copy cpm3.sys ..\..\Binary\ZPM3
copy zccp.com ..\..\Binary\ZPM3
copy zinstal.zpm ..\..\Binary\ZPM3
copy startzpm.com ..\..\Binary\ZPM3
copy makedos.com ..\..\Binary\ZPM3
copy gencpm.dat ..\..\Binary\ZPM3
copy bnkbios3.spr ..\..\Binary\ZPM3
copy bnkbdos3.spr ..\..\Binary\ZPM3
copy resbdos3.spr ..\..\Binary\ZPM3
