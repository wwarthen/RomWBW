@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF kbdinfo.asm kbdinfo.com kbdinfo.lst || exit /b

copy /Y kbdinfo.com ..\..\..\..\Binary\Apps\Test\ || exit /b
