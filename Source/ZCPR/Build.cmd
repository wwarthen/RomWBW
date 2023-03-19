@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zxcc;%PATH%

set TASMTABS=%TOOLS%\tasm32

set CPMDIR80=%TOOLS%/cpm/

zxcc MAC -ZCPR.ASM -$PO || exit /b
zxcc MLOAD25 -ZCPR.BIN=ZCPR.HEX || exit /b

zxcc MAC -BDLOC.ASM -$PO || exit /b
zxcc MLOAD25 -BDLOC.COM=BDLOC.HEX || exit /b
