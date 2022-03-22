@echo off
setlocal

set TOOLS=..\..\..\..\Tools

set PATH=%TOOLS%\zxcc;%PATH%

set CPMDIR80=%TOOLS%/cpm/

zxcc M80 -=2piotst/l || exit /b
zxcc L80 -2piotst,2piotst.com/n/e || exit /b

copy /Y 2piotst.com ..\..\..\..\Binary\Apps\Test\ || exit /b
