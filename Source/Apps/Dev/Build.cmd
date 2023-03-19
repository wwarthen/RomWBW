@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

echo Building Dev...
tasm -t80 -g3 -fFF dev.asm dev.com %dev.lst || exit /b

copy /Y dev.com ..\..\..\Binary\Apps\ || exit /b
rem copy /Y *.ovr ..\..\..\Binary\Apps\ || exit /b
rem copy /Y *.hlp ..\..\..\Binary\Apps\ || exit /b
rem copy /Y *.doc ..\..\..\Binary\Apps\ || exit /b
