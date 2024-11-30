@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -g3 -fFF talk.asm talk.com talk.lst || exit /b

copy /Y talk.com ..\..\..\Binary\Apps\ || exit /b
