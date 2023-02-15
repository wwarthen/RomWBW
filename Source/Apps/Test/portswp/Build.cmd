@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF portswp.asm portswp.com portswp.lst || exit /b

copy /Y portswp.com ..\..\..\..\Binary\Apps\Test\ || exit /b

