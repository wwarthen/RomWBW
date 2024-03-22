@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zxcc;%TOOLS%\cpmtools;%PATH%

set TASMTABS=%TOOLS%\tasm32

set CPMDIR80=%TOOLS%/cpm/
set INCDIR80=../

echo.
echo.
echo *** CPM Loader ***
echo.
zxcc RMAC -CPMLDR || exit /b
zxcc Z80ASM -UTIL/MF || exit /b
copy optdsk.lib ldropts.lib || exit /b
zxcc Z80ASM -BIOSLDR/MF || exit /b
move /Y biosldr.rel biosldrd.rel || exit /b
move /Y biosldr.lst biosldrd.lst || exit /b
zxcc LINK -CPMLDRD[L100]=CPMLDR,BIOSLDRD,UTIL || exit /b
move /Y cpmldrd.com cpmldr.bin || exit /b
copy optcmd.lib ldropts.lib || exit /b
zxcc Z80ASM -BIOSLDR/MF || exit /b
move /Y biosldr.rel biosldrc.rel || exit /b
move /Y biosldr.lst biosldrd.lst || exit /b
zxcc LINK -CPMLDRC[L100]=CPMLDR,BIOSLDRC,UTIL || exit /b
move /Y cpmldrc.com cpmldr.com || exit /b
rem pause

echo.
echo.
echo *** Resident CPM3 BIOS ***
echo.
copy optres.lib options.lib || exit /b
copy genres.dat gencpm.dat || exit /b
zxcc RMAC -BIOSKRNL || exit /b
zxcc RMAC -SCB || exit /b
zxcc Z80ASM -BOOT/MF || exit /b
zxcc Z80ASM -CHARIO/MF || exit /b
zxcc Z80ASM -MOVE/MF || exit /b
zxcc Z80ASM -DRVTBL/MF || exit /b
zxcc Z80ASM -DISKIO/MF || exit /b
zxcc Z80ASM -UTIL/MF || exit /b
zxcc LINK -BIOS3[OS]=BIOSKRNL,SCB,BOOT,CHARIO,MOVE,DRVTBL,DISKIO,UTIL || exit /b
zxcc GENCPM -AUTO -DISPLAY || exit /b
copy cpm3.sys cpm3res.sys || exit /b
rem pause

echo.
echo.
echo *** Banked CPM3 BIOS ***
echo.
copy optbnk.lib options.lib || exit /b
copy genbnk.dat gencpm.dat || exit /b
zxcc RMAC -BIOSKRNL || exit /b
zxcc RMAC -SCB || exit /b
zxcc Z80ASM -BOOT/MF || exit /b
zxcc Z80ASM -CHARIO/MF || exit /b
zxcc Z80ASM -MOVE/MF || exit /b
zxcc Z80ASM -DRVTBL/MF || exit /b
zxcc Z80ASM -DISKIO/MF || exit /b
zxcc Z80ASM -UTIL/MF || exit /b
zxcc LINK -BNKBIOS3[B]=BIOSKRNL,SCB,BOOT,CHARIO,MOVE,DRVTBL,DISKIO,UTIL || exit /b
zxcc GENCPM -AUTO -DISPLAY || exit /b
copy cpm3.sys cpm3bnk.sys || exit /b
rem pause

echo.
echo.
echo *** Banked ZPM3 BIOS ***
echo.
copy optzpm.lib options.lib || exit /b
copy genbnk.dat gencpm.dat || exit /b
zxcc RMAC -BIOSKRNL || exit /b
zxcc RMAC -SCB || exit /b
zxcc Z80ASM -BOOT/MF || exit /b
zxcc Z80ASM -CHARIO/MF || exit /b
zxcc Z80ASM -MOVE/MF || exit /b
zxcc Z80ASM -DRVTBL/MF || exit /b
zxcc Z80ASM -DISKIO/MF || exit /b
zxcc Z80ASM -UTIL/MF || exit /b
zxcc LINK -ZPMBIOS3[B]=BIOSKRNL,SCB,BOOT,CHARIO,MOVE,DRVTBL,DISKIO,UTIL || exit /b
rem zxcc GENCPM -AUTO -DISPLAY || exit /b
rem copy cpm3.sys zpm3.sys || exit /b
rem pause

rem *** Resident ***

rem copy cpm3res.sys cpm3.sys || exit /b
rem copy genres.dat getcpm.dat || exit /b

rem *** Banked ***

copy cpm3bnk.sys cpm3.sys || exit /b
copy genbnk.dat gencpm.dat || exit /b

rem Loader

tasm -t80 -g3 -fFF loader.asm loader.bin loader.lst || exit /b

copy /b loader.bin + cpmldr.bin cpmldr.sys || exit /b

rem Copy OS files to Binary directory

copy cpmldr.com ..\..\Binary\CPM3 || exit /b
copy cpmldr.sys ..\..\Binary\CPM3 || exit /b
copy ccp.com ..\..\Binary\CPM3 || exit /b
copy gencpm.com ..\..\Binary\CPM3 || exit /b
copy genres.dat ..\..\Binary\CPM3 || exit /b
copy genbnk.dat ..\..\Binary\CPM3 || exit /b
copy bios3.spr ..\..\Binary\CPM3 || exit /b
copy bnkbios3.spr ..\..\Binary\CPM3 || exit /b
copy bdos3.spr ..\..\Binary\CPM3 || exit /b
copy bnkbdos3.spr ..\..\Binary\CPM3 || exit /b
copy resbdos3.spr ..\..\Binary\CPM3 || exit /b
copy cpm3res.sys ..\..\Binary\CPM3 || exit /b
copy cpm3bnk.sys ..\..\Binary\CPM3 || exit /b
copy gencpm.dat ..\..\Binary\CPM3 || exit /b
copy cpm3.sys ..\..\Binary\CPM3 || exit /b
copy readme.1st ..\..\Binary\CPM3 || exit /b
copy cpm3fix.pat ..\..\Binary\CPM3 || exit /b