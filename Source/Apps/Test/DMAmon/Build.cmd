@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF dmamon.asm dmamon.com dmamon.lst || exit /b

copy /Y dmamon.com ..\..\..\..\Binary\Apps\Test\ || exit /b

