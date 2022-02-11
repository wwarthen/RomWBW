@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zxcc;%PATH%

set TASMTABS=%TOOLS%\tasm32

set CPMDIR80=%TOOLS%/cpm/

echo.
echo Building CBIOS for RomWBW...
echo.
tasm -t80 -g3 -dPLTWBW cbios.asm cbios_wbw.bin cbios_wbw.lst || exit /b
if errorlevel 1 goto :eof

echo.
echo Building CBIOS for UNA...
echo.
tasm -t80 -g3 -dPLTUNA cbios.asm cbios_una.bin cbios_una.lst || exit /b
if errorlevel 1 goto :eof
