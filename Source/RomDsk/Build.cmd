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

call :MakeDisk rom256_wbw 256 0x20000 wbw
call :MakeDisk rom256_una 256 0x20000 una

set RomApps=%RomApps1% %RomApps2%

call :MakeDisk rom512_wbw 512 0x60000 wbw
call :MakeDisk rom512_una 512 0x60000 una

call :MakeDisk rom1024_wbw 1024 0xE0000 wbw
call :MakeDisk rom1024_una 1024 0xE0000 una

goto :eof

:MakeDisk
set Output=%1
set RomSize=%2
set ImgSize=%3
set Bios=%4

echo Making ROM Disk %Output%

:: Create the empty disk image file
srec_cat -Generate 0 %ImgSize% --Constant 0xE5 -Output %Output%.dat -Binary || exit /b

:: Populate the disk image via cpmtools
cpmcp -f wbw_rom%RomSize% %Output%.dat ROM_%RomSize%KB/*.* 0: || exit /b
for %%f in (%RomApps%) do cpmcp -f wbw_rom%RomSize% %Output%.dat ../../Binary/Apps/%%f.com 0: || exit /b
cpmcp -f wbw_rom%RomSize% %Output%.dat ..\cpm22\cpm_%Bios%.sys 0:cpm.sys || exit /b
cpmcp -f wbw_rom%RomSize% %Output%.dat ..\zsdos\zsys_%Bios%.sys 0:zsys.sys || exit /b

:: Mark all disk files R/O for safety
cpmchattr -f wbw_rom%RomSize% %Output%.dat r 0:*.* || exit /b

goto :eof
