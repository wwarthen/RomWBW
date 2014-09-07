@echo off

setlocal

set PATH=..\Tools\tasm32;..\Tools\zx;%PATH%

set TASMTABS=..\Tools\tasm32

set ZXBINDIR=../tools/cpm/bin/
set ZXLIBDIR=../tools/cpm/lib/
set ZXINCDIR=../tools/cpm/include/

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