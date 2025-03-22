@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -g3 -fFF copysl.asm copysl.com copysl.lst || exit /b

copy /Y copysl.com ..\..\..\Binary\Apps\ || exit /b
copy /Y copysl.doc ..\..\..\Binary\Apps\ || exit /b
