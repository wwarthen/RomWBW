@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -g3 -fFF rtc.asm rtc.com rtc.lst || exit /b
tasm -t80 -g3 -fFF rtchb.asm rtchb.com rtchb.lst || exit /b

copy /Y rtc.com ..\..\..\Binary\Apps\ || exit /b
copy /Y rtchb.com ..\..\..\Binary\Apps\ || exit /b
