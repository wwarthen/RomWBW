@echo off

setlocal

set PATH=..\Tools\zx;%PATH%

set ZXBINDIR=../tools/cpm/bin/
set ZXLIBDIR=../tools/cpm/lib/
set ZXINCDIR=../tools/cpm/include/

zx ZMAC -ZSDOS -/P
zx LINK -ZSDOS[LD800]
ren zsdos.com zsdos.bin
