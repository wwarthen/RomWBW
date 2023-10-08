@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

echo Building HTalk...
tasm -t80 -g3 -fFF htalk.asm htalk.com %htalk.lst || exit /b

copy /Y htalk.com ..\..\..\Binary\Apps\ || exit /b
rem copy /Y *.ovr ..\..\..\Binary\Apps\ || exit /b
rem copy /Y *.hlp ..\..\..\Binary\Apps\ || exit /b
rem copy /Y *.doc ..\..\..\Binary\Apps\ || exit /b
