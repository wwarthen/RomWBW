@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -g3 -fFF banktest.asm banktest.com banktest.lst || exit /b

copy /Y banktest.com ..\..\..\..\Binary\Apps\Test\ || exit /b

