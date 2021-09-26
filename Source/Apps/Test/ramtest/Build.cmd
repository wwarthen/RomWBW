@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -b -fFF loader.asm loader.bin loader.lst || exit /b
tasm -t80 -b -fFF dbgmon.asm dbgmon.bin dbgmon.lst || exit /b

copy /Y /b loader.bin+dbgmon.bin ramtest.com || exit /b

copy /Y ramtest.com ..\..\..\..\Binary\Apps\Test\ || exit /b
