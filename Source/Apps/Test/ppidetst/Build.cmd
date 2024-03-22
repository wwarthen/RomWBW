@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF ppidetst.asm ppidetst.com ppidetst.lst || exit /b

copy /Y ppidetst.com ..\..\..\..\Binary\Apps\Test\ || exit /b

