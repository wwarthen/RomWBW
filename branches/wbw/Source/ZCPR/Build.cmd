@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zx;%PATH%

set TASMTABS=%TOOLS%\tasm32

set ZXBINDIR=%TOOLS%/cpm/bin/
set ZXLIBDIR=%TOOLS%/cpm/lib/
set ZXINCDIR=%TOOLS%/cpm/include/

zx MAC -ZCPR.ASM -$PO
zx MLOAD25 -ZCPR.BIN=ZCPR.HEX

zx MAC -BDLOC.ASM -$PO
zx MLOAD25 -BDLOC.COM=BDLOC.HEX
