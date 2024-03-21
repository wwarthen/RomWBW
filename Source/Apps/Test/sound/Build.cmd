@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -g3 -fFF sound.asm sound.com sound.lst || exit /b
tasm -t80 -g3 -fFF ay-test.asm ay-test.com ay-test.lst || exit /b

copy /Y sound.com ..\..\..\..\Binary\Apps\Test\ || exit /b
copy /Y ay-test.com ..\..\..\..\Binary\Apps\Test\ || exit /b
