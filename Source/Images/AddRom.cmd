@echo off
setlocal

set PATH=..\..\Tools\cpmtools;%PATH%
set BINLOC=..\..\Binary
set DISKIMG=hd1k_combo.img

if "%1"=="" goto :usage

if not exist %BINLOC%\%DISKIMG% goto :noimage

if not exist %BINLOC%\%1.rom goto :nofile

echo.

cpmrm.exe -f wbw_hd1k_0 %BINLOC%/%DISKIMG% 0:rom.img
cpmcp.exe -f wbw_hd1k_0 %BINLOC%/%DISKIMG% %BINLOC%/%1.rom 0:rom.img

if errorlevel 1 goto :err

::cpmls.exe -f wbw_hd1k_0 %BINLOC%/%DISKIMG% 0:rom.img

echo %1.rom has been added to %DISKIMG% as ROM.IMG in user area 0
echo.
goto :eof

:noimage
echo.
echo %BINLOC%\%DISKIMG% file not found!!!
echo.
goto :eof

:nofile
echo.
echo %BINLOC%\%1.rom file not found!!!
echo.
goto :eof

:usage
echo.
echo Usage:
echo   AddRom romname
echo.
echo romname is the root filename of an existing ROM image in the %BINLOC% directory
echo.
echo Example:
echo   AddRom RCZ80_std
echo.
goto :eof

:err
echo.
echo An error occurred copying %1.rom into hd1k_combo.img!
echo.