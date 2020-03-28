@echo off
setlocal

set PATH=%PATH%;..\..\..\Tools\zx;..\..\..\Tools\cpmtools;

set ZXBINDIR=../../../tools/cpm/bin/
set ZXLIBDIR=../../../tools/cpm/lib/
set ZXINCDIR=../../../tools/cpm/include/

rem zx Z80ASM -z34rcp11/MF
zx ZMAC -z34rcp11.z80 -/P
