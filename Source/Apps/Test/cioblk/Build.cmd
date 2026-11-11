@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -g3 -fFF cioblk.asm cioblk.com cioblk.lst || exit /b

copy /Y cioblk.com ..\..\..\..\Binary\Apps\Test\ || exit /b

