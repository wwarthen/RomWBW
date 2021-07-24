@echo off
setlocal

set PATH=%PATH%;..\..\..\Tools\zx;..\..\..\Tools\cpmtools;

set ZXBINDIR=../../../tools/cpm/bin/
set ZXLIBDIR=../../../tools/cpm/lib/
set ZXINCDIR=../../../tools/cpm/include/

zx Z80ASM -nzfcp13/MF || exit /b
rem zx ZMAC -nzfcp13.z80 -/P || exit /b
