@echo off
setlocal

set PATH=%PATH%;..\..\..\Tools\zx;..\..\..\Tools\cpmtools;

set ZXBINDIR=../../../tools/cpm/bin/
set ZXLIBDIR=../../../tools/cpm/lib/
set ZXINCDIR=../../../tools/cpm/include/

copy ..\z3base.lib . || exit /b
zx ZMAC -zcpr33.z80 -/P || exit /b
del z3base.lib || exit /b
move zcpr33.rel .. || exit /b