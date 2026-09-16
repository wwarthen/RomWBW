@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -g3 -fFF -dCPM devlist.asm devlist.com devlist.lst || exit /b

copy /Y devlist.com ..\..\..\Binary\Apps\ || exit /b
