@echo off
setlocal

set PATH=%PATH%;..\..\..\Tools\zx;..\..\..\Tools\cpmtools;

set ZXBINDIR=../../../tools/cpm/bin/
set ZXLIBDIR=../../../tools/cpm/lib/
set ZXINCDIR=../../../tools/cpm/include/

copy ..\z3baset.lib . || exit /b
zx ZMAC -zcpr33t.z80 -/P || exit /b
del z3baset.lib || exit /b
move zcpr33t.rel .. || exit /b

copy ..\z3basen.lib . || exit /b
zx ZMAC -zcpr33n.z80 -/P || exit /b
del z3basen.lib || exit /b
move zcpr33n.rel .. || exit /b