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
echo *** Resident BIOS ***
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
zx LINK -BIOS3[OS]=BIOSKRNL,SCB,BOOT,CHARIO,MOVE,DRVTBL,DISKIO
zx GENCPM -AUTO -DISPLAY
copy cpm3.sys cpm3res.sys
rem pause

rem Banked CPM3
echo.
echo.
echo *** Banked BIOS ***
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
zx LINK -BNKBIOS3[B]=BIOSKRNL,SCB,BOOT,CHARIO,MOVE,DRVTBL,DISKIO
zx GENCPM -AUTO -DISPLAY
copy cpm3.sys cpm3bnk.sys
rem pause

rem *** Resident ***
rem copy cpm3res.sys cpm3.sys
rem copy genres.dat getcpm.dat

rem *** Banked ***
copy cpm3bnk.sys cpm3.sys
copy genbnk.dat gencpm.dat

rem Update cpm_hd.img
echo.
echo.
echo *** Update Disk Image ***
echo.
for %%f in (
  cpmldr.com
  ccp.com
  gencpm.com
  genres.dat
  genbnk.dat
  bios3.spr
  bnkbios3.spr
  bdos3.spr
  bnkbdos3.spr
  resbdos3.spr
  cpm3res.sys
  cpm3bnk.sys
  gencpm.dat
  cpm3.sys
  readme.1st
  cpm3fix.pat
) do call :upd_img %%f
goto :eof

:upd_img
echo   %1...
cpmrm.exe -f wbw_hd0 ../../Binary/hd_cpm3.img 0:%1
cpmcp.exe -f wbw_hd0 ../../Binary/hd_cpm3.img %1 0:%1
goto :eof