@echo off

setlocal

set PATH=..\Tools\zx;%PATH%

set ZXBINDIR=../tools/cpm/bin/
set ZXLIBDIR=../tools/cpm/lib/
set ZXINCDIR=../tools/cpm/include/

zx M80 -=zcpr
zx L80 -zcpr,zcpr.bin/n/e