@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -g3 -fFF timer.asm timer.com timer.lst || exit /b

copy /Y timer.com ..\..\..\Binary\Apps\ || exit /b