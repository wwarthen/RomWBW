@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF portscan.asm portscan.com portscan.lst || exit /b

copy /Y portscan.com ..\..\..\..\Binary\Apps\Test\ || exit /b

