@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zx;%PATH%

set TASMTABS=%TOOLS%\tasm32

set ZXBINDIR=%TOOLS%/cpm/bin/
set ZXLIBDIR=%TOOLS%/cpm/lib/
set ZXINCDIR=%TOOLS%/cpm/include/

echo.
echo Building CBIOS for RomWBW...
echo.
tasm -t80 -b -g3 -fFF -dPLTWBW cbios.asm cbios_wbw.bin cbios_wbw.lst

echo.
echo Building CBIOS for UNA...
echo.
tasm -t80 -b -g3 -fFF -dPLTUNA cbios.asm cbios_una.bin cbios_una.lst
