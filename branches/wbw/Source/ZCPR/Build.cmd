@echo off

setlocal

set PATH=..\Tools\zx;%PATH%

set ZXBINDIR=../tools/cpm/bin/
set ZXLIBDIR=../tools/cpm/lib/
set ZXINCDIR=../tools/cpm/include/

zx MAC -ZCPR.ASM -$PO
zx MLOAD25 -ZCPR.BIN=ZCPR.HEX

zx MAC -BDLOC.ASM -$PO
zx MLOAD25 -BDLOC.COM=BDLOC.HEX
