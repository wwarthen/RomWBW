@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -b -fFF fdu.asm fdu.com fdu.lst || exit /b

copy /Y fdu.com ..\..\..\Binary\Apps\ || exit /b
copy /Y fdu.doc ..\..\..\Binary\Apps\ || exit /b
