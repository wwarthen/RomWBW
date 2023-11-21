@echo off
setlocal

set PATH=..\..\Tools\cpmtools;%PATH%
set ROMLOC=..\..\Binary

if "%1"=="" goto :usage

if not exist %ROMLOC%\%1.rom goto :nofile

echo.

cpmrm.exe -f wbw_hd1k_0 %ROMLOC%/hd1k_combo.img 0:rom.img
cpmcp.exe -f wbw_hd1k_0 %ROMLOC%/hd1k_combo.img %ROMLOC%/%1.rom 0:rom.img

if errorlevel 1 goto :err

::cpmls.exe -f wbw_hd1k_0 %ROMLOC%/hd1k_combo.img 0:rom.img

echo %1.rom has been added to hd1k_combo.img in user area 0
echo.
goto :eof

:nofile
echo.
echo %ROMLOC%\%1.rom file not found!!!
echo.
goto :eof

:usage
echo.
echo Usage:
echo   AddRom romname
echo.
echo romname is the root filename of an existing ROM image in the %ROMLOC% directory
echo.
echo Example:
echo   AddRom RCZ80_std
echo.
goto :eof

:err
echo.
echo An error occurred copying %1.rom into hd1k_combo.img!
echo.