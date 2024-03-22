@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF vdctest.asm vdctest.com vdctest.lst || exit /b
tasm -t180 -g3 -fFF vdconly.asm vdconly.com vdconly.lst || exit /b

copy /Y vdctest.com ..\..\..\..\Binary\Apps\Test\ || exit /b
copy /Y vdconly.com ..\..\..\..\Binary\Apps\Test\ || exit /b
