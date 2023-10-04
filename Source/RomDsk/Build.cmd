@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zxcc;%TOOLS%\srecord;%TOOLS%\cpmtools;%PATH%

set TASMTABS=%TOOLS%\tasm32

set CPMDIR80=%TOOLS%/cpm/

set RomApps1=assign mode rtc syscopy xm
set RomApps2=fdu format survey sysgen talk timer cpuspd

::
:: Make all variants of the ROM Disk contents image.  Three sizes are
:: created for each of the different ROM sizes possible (256K, 512K, 1024K).
:: Also, the UNA ROM Disks contain different versions of the OS files.
:: 
:: Note that the sizes specified below are not the size of the final
:: ROM.  The ROM reserves 128K for code space.  So, the size created is
:: the final ROM size less 128K.
::

set RomApps=

copy NUL rom128_wbw.dat
copy NUL rom128_una.dat

:: MakeDisk <OutputFile> <ImageSize> <Format> <Directory> <Bios>

set RomApps=%RomApps1%

call :MakeDisk rom256_wbw wbw_rom256 ROM_256KB 0x20000 wbw
call :MakeDisk rom256_una wbw_rom256 ROM_256KB 0x20000 una

set RomApps=%RomApps1% %RomApps2%

call :MakeDisk rom512_wbw wbw_rom512 ROM_512KB 0x60000 wbw
call :MakeDisk rom512_una wbw_rom512 ROM_512KB 0x60000 una

call :MakeDisk rom1024_wbw wbw_rom1024 ROM_1024KB 0xE0000 wbw
call :MakeDisk rom1024_una wbw_rom1024 ROM_1024KB 0xE0000 una

call :MakeDisk ram512_wbw wbw_ram512 RAM_512KB 0x40000 wbw

call :MakeDisk ram1024_wbw wbw_ram1024 RAM_1024KB 0xC0000 wbw

goto :eof

:MakeDisk
set Output=%1
set DiskDef=%2
set Dir=%3
set ImgSize=%4
set Bios=%5

echo Making ROM Disk %Output%

:: Create the empty disk image file
srec_cat -Generate 0 %ImgSize% --Constant 0xE5 -Output %Output%.dat -Binary || exit /b

:: Populate the disk image via cpmtools
cpmcp -f %DiskDef% %Output%.dat %Dir%/*.* 0: || exit /b
for %%f in (%RomApps%) do cpmcp -f %DiskDef% %Output%.dat ../../Binary/Apps/%%f.com 0: || exit /b
cpmcp -f %DiskDef% %Output%.dat ..\cpm22\cpm_%Bios%.sys 0:cpm.sys || exit /b
cpmcp -f %DiskDef% %Output%.dat ..\zsdos\zsys_%Bios%.sys 0:zsys.sys || exit /b

:: Mark all disk files R/O for safety
cpmchattr -f %DiskDef% %Output%.dat r 0:*.* || exit /b

goto :eof
