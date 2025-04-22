@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -g3 -fFF slabel.asm slabel.com slabel.lst || exit /b

copy /Y slabel.com ..\..\..\Binary\Apps\ || exit /b
