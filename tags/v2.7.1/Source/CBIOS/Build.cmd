@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zx;%PATH%

set TASMTABS=%TOOLS%\tasm32

set ZXBINDIR=%TOOLS%/cpm/bin/
set ZXLIBDIR=%TOOLS%/cpm/lib/
set ZXINCDIR=%TOOLS%/cpm/include/

call :asm cbios || goto :eof

goto :eof

:asm
echo.
echo Building %1...
tasm -t80 -b -g3 -fFF %1.asm %1.bin %1.lst
goto :eof
