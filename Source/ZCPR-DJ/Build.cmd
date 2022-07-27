@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zxcc;%PATH%

set TASMTABS=%TOOLS%\tasm32

set CPMDIR80=%TOOLS%/cpm/

zxcc M80 -=zcpr/l || exit /b
zxcc L80 -zcpr,zcpr.bin/n/e || exit /b

zxcc M80 -=zcprdemo/l || exit /b
zxcc L80 -zcprdemo,zcprdemo/n/e || exit /b