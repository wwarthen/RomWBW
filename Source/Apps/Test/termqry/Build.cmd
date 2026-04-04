@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -g3 -fFF termqry.asm termqry.com termqry.lst || exit /b

copy /Y termqry.com ..\..\..\..\Binary\Apps\Test\ || exit /b
