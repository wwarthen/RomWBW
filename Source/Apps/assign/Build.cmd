@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -g3 -fFF assign.asm assign.com assign.lst || exit /b

copy /Y assign.com ..\..\..\Binary\Apps\ || exit /b
