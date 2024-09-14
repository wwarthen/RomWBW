@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -g3 -fFF testh8p.asm testh8p.com testh8p.lst || exit /b

copy /Y testh8p.com ..\..\..\..\Binary\Apps\Test\ || exit /b
