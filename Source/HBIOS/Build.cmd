@echo off
setlocal

::
:: Build [<platform> [<config> [<romsize> [<romname>]]]]
::

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zx;%PATH%

set TASMTABS=%TOOLS%\tasm32

set ZXBINDIR=%TOOLS%/cpm/bin/
set ZXLIBDIR=%TOOLS%/cpm/lib/
set ZXINCDIR=%TOOLS%/cpm/include/

PowerShell -ExecutionPolicy Unrestricted .\Build.ps1 %* || exit /b

call build_env.cmd

echo Building %ROMSize%K ROM %ROMName% for Z%CPUType% CPU...

if %Platform%==UNA goto :UNA

copy ..\Fonts\font*.asm . || exit /b

::
:: Build HBIOS Core (all variants)
::
tasm -t%CPUType% -g3 -dROMBOOT hbios.asm hbios_rom.bin hbios_rom.lst || exit /b
tasm -t%CPUType% -g3 -dAPPBOOT hbios.asm hbios_app.bin hbios_app.lst || exit /b
tasm -t%CPUType% -g3 -dIMGBOOT hbios.asm hbios_img.bin hbios_img.lst || exit /b

::
:: Build ROM Components
::
call :asm dbgmon
call :asm romldr
call :asm eastaegg
call :asm nascom
call :asm tastybasic
call :asm game
call :asm usrrom
call :asm updater
call :asm imgpad2

::
:: Create ROM bank images by assembling components
::

copy /b romldr.bin + dbgmon.bin + ..\zsdos\zsys_wbw.bin + ..\cpm22\cpm_wbw.bin osimg.bin || exit /b
copy /b romldr.bin + dbgmon.bin + ..\zsdos\zsys_wbw.bin osimg_small.bin || exit /b
copy /b ..\Forth\camel80.bin + nascom.bin + tastybasic.bin + game.bin + eastaegg.bin + netboot.mod + updater.bin + usrrom.bin osimg1.bin || exit /b
copy /b imgpad2.bin osimg2.bin || exit /b

::
:: Create final ROM images
::

set RomDiskDat=
if %ROMSize% GTR 128 set RomDiskDat=..\RomDsk\rom%ROMSize%_wbw.dat

copy /b hbios_rom.bin + osimg.bin + osimg1.bin + osimg2.bin + ..\RomDsk\rom%ROMSize%_wbw.dat %ROMName%.rom || exit /b
copy /b hbios_rom.bin + osimg.bin + osimg1.bin + osimg2.bin %ROMName%.upd || exit /b
copy /b hbios_app.bin + osimg_small.bin %ROMName%.com || exit /b

::
:: Copy to output directory
::

copy %ROMName%.rom ..\..\Binary || exit /b
copy %ROMName%.upd ..\..\Binary || exit /b
copy %ROMName%.com ..\..\Binary || exit /b

goto :eof

::
:: UNA specific ROM creation
::

:UNA

call :asm dbgmon
call :asm romldr

copy /b romldr.bin + dbgmon.bin + ..\zsdos\zsys_una.bin + ..\cpm22\cpm_una.bin osimg.bin || exit /b

copy /b osimg.bin ..\..\Binary\UNA_WBW_SYS.bin || exit /b
copy /b ..\RomDsk\rom%ROMSize%_una.dat ..\..\Binary\UNA_WBW_ROM%ROMSize%.bin || exit /b

copy /b ..\UBIOS\UNA-BIOS.BIN + osimg.bin + ..\UBIOS\FSFAT.BIN + ..\RomDsk\rom%ROMSize%_una.dat %ROMName%.rom || exit /b

copy %ROMName%.rom ..\..\Binary || exit /b

goto :eof

:asm
echo.
echo Building %1...
tasm -t80 -g3 -fFF %1.asm %1.bin %1.lst || exit /b
goto :eof

