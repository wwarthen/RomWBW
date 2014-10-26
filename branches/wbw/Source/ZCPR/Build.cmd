@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zx;%PATH%

set TASMTABS=%TOOLS%\tasm32

set ZXBINDIR=%TOOLS%/cpm/bin/
set ZXLIBDIR=%TOOLS%/cpm/lib/
set ZXINCDIR=%TOOLS%/cpm/include/

zx MAC -stdio -ZCPR.ASM -$PO
zx MLOAD25 -stdio -ZCPR.BIN=ZCPR.HEX

zx MAC -stdio -BDLOC.ASM -$PO
zx MLOAD25 -stdio -BDLOC.COM=BDLOC.HEX
