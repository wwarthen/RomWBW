@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\zx;%TOOLS%\cpmtools;%PATH%

set ZXBINDIR=%TOOLS%/cpm/bin/
set ZXLIBDIR=%TOOLS%/cpm/lib/
set ZXINCDIR=%TOOLS%/cpm/include/

rem cmd

rem CPM Loader
echo.
echo.
echo *** CPM Loader ***
echo.
zx RMAC -CPMLDR
zx Z80ASM -BIOSLDR/MF
zx LINK -CPMLDR[L100]=CPMLDR,BIOSLDR
rem pause

rem Resident CPM3
echo.
echo.
echo *** Resident CPM3 BIOS ***
echo.
copy optres.lib options.lib
copy genres.dat gencpm.dat
zx RMAC -BIOSKRNL
zx RMAC -SCB
zx Z80ASM -BOOT/MF
zx Z80ASM -CHARIO/MF
zx Z80ASM -MOVE/MF
zx Z80ASM -DRVTBL/MF
zx Z80ASM -DISKIO/MF
zx Z80ASM -UTIL/MF
zx LINK -BIOS3[OS]=BIOSKRNL,SCB,BOOT,CHARIO,MOVE,DRVTBL,DISKIO,UTIL
zx GENCPM -AUTO -DISPLAY
copy cpm3.sys cpm3res.sys
rem pause

rem Banked CPM3
echo.
echo.
echo *** Banked CPM3 BIOS ***
echo.
copy optbnk.lib options.lib
copy genbnk.dat gencpm.dat
zx RMAC -BIOSKRNL
zx RMAC -SCB
zx Z80ASM -BOOT/MF
zx Z80ASM -CHARIO/MF
zx Z80ASM -MOVE/MF
zx Z80ASM -DRVTBL/MF
zx Z80ASM -DISKIO/MF
zx Z80ASM -UTIL/MF
zx LINK -BNKBIOS3[B]=BIOSKRNL,SCB,BOOT,CHARIO,MOVE,DRVTBL,DISKIO,UTIL
zx GENCPM -AUTO -DISPLAY
copy cpm3.sys cpm3bnk.sys
rem pause

rem Banked ZPM3
echo.
echo.
echo *** Banked ZPM3 BIOS ***
echo.
copy optzpm.lib options.lib
copy genbnk.dat gencpm.dat
zx RMAC -BIOSKRNL
zx RMAC -SCB
zx Z80ASM -BOOT/MF
zx Z80ASM -CHARIO/MF
zx Z80ASM -MOVE/MF
zx Z80ASM -DRVTBL/MF
zx Z80ASM -DISKIO/MF
zx Z80ASM -UTIL/MF
zx LINK -ZPMBIOS3[B]=BIOSKRNL,SCB,BOOT,CHARIO,MOVE,DRVTBL,DISKIO,UTIL
rem zx GENCPM -AUTO -DISPLAY
rem copy cpm3.sys zpm3.sys
rem pause

rem *** Resident ***
rem copy cpm3res.sys cpm3.sys
rem copy genres.dat getcpm.dat

rem *** Banked ***
copy cpm3bnk.sys cpm3.sys
copy genbnk.dat gencpm.dat
