@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF cpuspd.asm cpuspd.com cpuspd.lst || exit /b

copy /Y cpuspd.com ..\..\..\Binary\Apps\ || exit /b
