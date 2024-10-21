@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -g3 -fFF format.asm format.com format.lst || exit /b

copy /Y format.com ..\..\..\Binary\Apps\ || exit /b
