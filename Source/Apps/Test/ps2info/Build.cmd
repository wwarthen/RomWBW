@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF ps2info.asm ps2info.com ps2info.lst || exit /b

copy /Y ps2info.com ..\..\..\..\Binary\Apps\Test\ || exit /b
