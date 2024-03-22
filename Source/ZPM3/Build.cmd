@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zxcc;%TOOLS%\cpmtools;%PATH%

set TASMTABS=%TOOLS%\tasm32

set CPMDIR80=%TOOLS%/cpm/

copy ..\ZCCP\ccp.com zccp.com || exit /b
copy ..\ZCCP\zinstal.zpm . || exit /b
copy ..\ZCCP\startzpm.com . || exit /b
copy ..\CPM3\genbnk.dat . || exit /b
copy ..\CPM3\zpmbios3.spr bnkbios3.spr || exit /b
copy ..\CPM3\gencpm.com . || exit /b
copy ..\CPM3\util.rel . || exit /b
copy ..\CPM3\biosldrd.rel . || exit /b
copy ..\CPM3\biosldrc.rel . || exit /b
copy ..\CPM3\cpmldr.com . || exit /b
copy ..\CPM3\cpmldr.sys . || exit /b

rem ZPM Loader
echo.
echo.
echo *** ZPM Loader ***
echo.
zxcc LINK -ZPMLDRD[L100]=ZPM3LDR,BIOSLDRD,UTIL || exit /b
:: zxcc SLRNK -ZPM3LDR,BIOSLDRD,UTIL,ZPMLDRD/N/E
move /Y zpmldrd.com zpmldr.bin || exit /b
zxcc LINK -ZPMLDRC[L100]=ZPM3LDR,BIOSLDRC,UTIL || exit /b
:: zxcc SLRNK -ZPM3LDR,BIOSLDRC,UTIL,ZPMLDRC/N/E
move /Y zpmldrc.com zpmldr.com || exit /b
rem pause

rem Banked ZPM3
echo.
echo.
echo *** Banked ZPM3 ***
echo.
copy genbnk.dat gencpm.dat || exit /b
zxcc gencpm -auto -display || exit /b
rem pause

rem ZPM3 Tools
zxcc Z80ASM -clrhist/F || exit /b
zxcc Z80ASM -setz3/F || exit /b
zxcc Z80ASM -autotog/F || exit /b

rem Loader

tasm -t80 -g3 -fFF loader.asm loader.bin loader.lst || exit /b

copy /b loader.bin + zpmldr.bin zpmldr.sys || exit /b

rem Copy OS files to Binary directory

copy zpmldr.com ..\..\Binary\ZPM3 || exit /b
copy zpmldr.sys ..\..\Binary\ZPM3 || exit /b
copy cpmldr.com ..\..\Binary\ZPM3 || exit /b
copy cpmldr.sys ..\..\Binary\ZPM3 || exit /b
copy autotog.com ..\..\Binary\ZPM3 || exit /b
copy clrhist.com ..\..\Binary\ZPM3 || exit /b
copy setz3.com ..\..\Binary\ZPM3 || exit /b
copy cpm3.sys ..\..\Binary\ZPM3 || exit /b
copy zccp.com ..\..\Binary\ZPM3 || exit /b
copy zinstal.zpm ..\..\Binary\ZPM3 || exit /b
copy startzpm.com ..\..\Binary\ZPM3 || exit /b
copy makedos.com ..\..\Binary\ZPM3 || exit /b
copy gencpm.dat ..\..\Binary\ZPM3 || exit /b
copy bnkbios3.spr ..\..\Binary\ZPM3 || exit /b
copy bnkbdos3.spr ..\..\Binary\ZPM3 || exit /b
copy resbdos3.spr ..\..\Binary\ZPM3 || exit /b
