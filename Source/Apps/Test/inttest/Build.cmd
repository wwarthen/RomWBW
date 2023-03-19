@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF inttest.asm inttest.com inttest.lst || exit /b

copy /Y inttest.com ..\..\..\..\Binary\Apps\Test\ || exit /b

