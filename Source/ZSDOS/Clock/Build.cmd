@echo off
setlocal

set TOOLS=../../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zxcc;%PATH%

set TASMTABS=%TOOLS%\tasm32

set CPMDIR80=%TOOLS%/cpm/

zxcc ZMAC -WBWCLK -/P || exit /b
