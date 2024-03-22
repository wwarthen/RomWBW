@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF tstdskng.asm tstdskng.com tstdskng.lst || exit /b

copy /Y tstdskng.com ..\..\..\..\Binary\Apps\Test\ || exit /b

