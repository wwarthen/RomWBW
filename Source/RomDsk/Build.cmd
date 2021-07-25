@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zx;%TOOLS%\srecord;%TOOLS%\cpmtools;%PATH%

set TASMTABS=%TOOLS%\tasm32

set ZXBINDIR=%TOOLS%/cpm/bin/
set ZXLIBDIR=%TOOLS%/cpm/lib/
set ZXINCDIR=%TOOLS%/cpm/include/

::
:: Make all variants of the ROM Disk contents image.  Three sizes are
:: created for each of the different ROM sizes possible (256K, 512K, 1024K).
:: Also, the UNA ROM Disks contain different versions of the OS files.
:: 
:: Note that the sizes specified below are not the size of the final
:: ROM.  The ROM reserves 128K for code space.  So, the size created is
:: the final ROM size less 128K.
::

:: MakeDisk <OutputFile> <ImageSize> <Format> <Directory> <Bios>

set RomApps=assign mode rtc syscopy xm

call :MakeDisk rom256_wbw 0x20000 wbw_rom256 ROM_256KB wbw
call :MakeDisk rom256_una 0x20000 wbw_rom256 ROM_256KB una

set RomApps=%RomApps% fdu format survey sysgen talk timer inttest

call :MakeDisk rom512_wbw 0x60000 wbw_rom512 ROM_512KB wbw
call :MakeDisk rom512_una 0x60000 wbw_rom512 ROM_512KB una

call :MakeDisk rom1024_wbw 0xE0000 wbw_rom1024 ROM_1024KB wbw
call :MakeDisk rom1024_una 0xE0000 wbw_rom1024 ROM_1024KB una

goto :eof

:MakeDisk
set Output=%1
set Size=%2
set Format=%3
set Content=%4
set Bios=%5

echo Making ROM Disk %Output%

srec_cat -Generate 0 %Size% --Constant 0xE5 -Output %Output%.dat -Binary || exit /b

cpmcp -f %Format% %Output%.dat %Content%/*.* 0: || exit /b
for %%f in (%RomApps%) do cpmcp -f %Format% %Output%.dat ../../Binary/Apps/%%f.com 0: || exit /b
cpmcp -f %Format% %Output%.dat ..\cpm22\cpm_%Bios%.sys 0:cpm.sys || exit /b
cpmcp -f %Format% %Output%.dat ..\zsdos\zsys_%Bios%.sys 0:zsys.sys || exit /b

cpmchattr -f %Format% %Output%.dat r 0:*.* || exit /b

goto :eof
