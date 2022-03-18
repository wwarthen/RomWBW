@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF piomon.asm piomon.com piomon.lst || exit /b

copy /Y piomon.com ..\..\..\..\Binary\Apps\Test\ || exit /b
