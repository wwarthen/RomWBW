@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zx;%PATH%

set TASMTABS=%TOOLS%\tasm32

set ZXBINDIR=%TOOLS%/cpm/bin/
set ZXLIBDIR=%TOOLS%/cpm/lib/
set ZXINCDIR=%TOOLS%/cpm/include/

call :asm SysCopy || goto :eof
call :asm Assign || goto :eof
call :asm Format || goto :eof
call :asm Talk || goto :eof

zx Z80ASM -SYSGEN/F

goto :eof

:asm
echo.
echo Building %1...
tasm -t80 -b -g3 -fFF %1.asm %1.com %1.lst
goto :eof