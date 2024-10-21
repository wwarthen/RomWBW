@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -g3 -fFF mode.asm mode.com mode.lst || exit /b

copy /Y mode.com ..\..\..\Binary\Apps\ || exit /b
