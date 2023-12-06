@echo off
setlocal

set TOOLS=..\..\..\Tools
set PATH=%PATH%;%TOOLS%\zxcc;%TOOLS%\cpmtools;
set CPMDIR80=%TOOLS%/cpm/

copy ..\z3base.lib . || exit /b
zxcc ZMAC -zcpr33.z80 -/P || exit /b
del z3base.lib || exit /b
move zcpr33.rel .. || exit /b