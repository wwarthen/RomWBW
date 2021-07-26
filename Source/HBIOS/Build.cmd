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

::
:: This PowerShell script validates the build variables passed in.  If
:: necessary, the user is prmopted to pick the variables.  It then creates
:: an include file that is imbedded in the HBIOS assembly (build.inc).
:: It also creates a batch command file that sets environment variables
:: for use by the remainder of this batch file (build_env.cmd).
::

PowerShell -ExecutionPolicy Unrestricted .\Build.ps1 %* || exit /b

::
:: Below, we process the command file created by the PowerShell script.
:: This sets the environment variables: Platform, Config, ROMName,
:: ROMSize, & CPUType.
::

call build_env.cmd

::
:: Start of the actual build process for a given ROM.
::

echo Building %ROMSize%K ROM %ROMName% for Z%CPUType% CPU...

::
:: UNA is a special case, check for it and jump if needed.
::

if %Platform%==UNA goto :UNA

::
:: Bring the previously build font files into this directory
::

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
:: Create additional ROM bank images by assembling components into
:: 32K chunks which can be concatenated later.  Note that
:: osimg_small is a special case because it is 20K in size.  This
:: image is subsequently used to generate the .com loadable file.
::

copy /b romldr.bin + dbgmon.bin + ..\zsdos\zsys_wbw.bin + ..\cpm22\cpm_wbw.bin osimg.bin || exit /b
copy /b ..\Forth\camel80.bin + nascom.bin + tastybasic.bin + game.bin + eastaegg.bin + netboot.mod + updater.bin + usrrom.bin osimg1.bin || exit /b
copy /b imgpad2.bin osimg2.bin || exit /b

copy /b romldr.bin + dbgmon.bin + ..\zsdos\zsys_wbw.bin osimg_small.bin || exit /b

::
:: Create final images (.rom, .upd, & .com)
:: The previously created bank images are concatenated as needed.
::
:: The .rom image is made up of 4 banks followed by the ROM Disk.  This
:: is for programming onto a ROM.
::
:: The .upd image is the same as above, but without the the ROM Disk.
:: This is so you can update just the code portion of your ROM without
:: updating the ROM Disk contents.
::
:: The .com image is a scaled down version of the ROM that you can run
:: as a standard application under an OS and it will replace your
:: HBIOS on the fly for testing purposes.
::

copy /b hbios_rom.bin + osimg.bin + osimg1.bin + osimg2.bin + ..\RomDsk\rom%ROMSize%_wbw.dat %ROMName%.rom || exit /b
copy /b hbios_rom.bin + osimg.bin + osimg1.bin + osimg2.bin %ROMName%.upd || exit /b
copy /b hbios_app.bin + osimg_small.bin %ROMName%.com || exit /b

::
:: Copy results to output directory
::

copy %ROMName%.rom ..\..\Binary || exit /b
copy %ROMName%.upd ..\..\Binary || exit /b
copy %ROMName%.com ..\..\Binary || exit /b

goto :eof

::
:: UNA specific ROM creation
::

:UNA

::
:: This process is basically equivalent to the one above, but tailored
:: for the UNA BIOS.
::

:: Build ROM components required by UNA
call :asm dbgmon
call :asm romldr

:: Create the OS bank
copy /b romldr.bin + dbgmon.bin + ..\zsdos\zsys_una.bin + ..\cpm22\cpm_una.bin osimg.bin || exit /b

:: Copy OS Bank and ROM Disk image files to output
copy /b osimg.bin ..\..\Binary\UNA_WBW_SYS.bin || exit /b
copy /b ..\RomDsk\rom%ROMSize%_una.dat ..\..\Binary\UNA_WBW_ROM%ROMSize%.bin || exit /b

:: Create the final ROM image
copy /b ..\UBIOS\UNA-BIOS.BIN + osimg.bin + ..\UBIOS\FSFAT.BIN + ..\RomDsk\rom%ROMSize%_una.dat %ROMName%.rom || exit /b

:: Copy to output
copy %ROMName%.rom ..\..\Binary || exit /b

goto :eof

::
:: Simple procedure to assemble a specified component via TASM.
::

:asm

echo.
echo Building %1...
tasm -t80 -g3 -fFF %1.asm %1.bin %1.lst || exit /b

goto :eof

