@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zxcc;%PATH%

set TASMTABS=%TOOLS%\tasm32

set CPMDIR80=%TOOLS%/cpm/

zxcc zsm =camel80.azm -/l || exit /b
zxcc link -CAMEL80.BIN[L200]=CAMEL80 || exit /b


