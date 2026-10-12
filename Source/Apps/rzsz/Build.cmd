@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -g3 -fFF rz.asm rz.com rz.lst || exit /b
tasm -t80 -g3 -fFF sz.asm sz.com sz.lst || exit /b

copy /Y rz.com ..\..\..\Binary\Apps\ || exit /b
copy /Y sz.com ..\..\..\Binary\Apps\ || exit /b
