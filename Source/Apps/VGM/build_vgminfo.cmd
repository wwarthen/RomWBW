@echo off
setlocal

set TOOLS=..\..\..\Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -b -g3 -fFF vgminfo.asm vgminfo.com vgminfo.lst || exit /b

echo.
echo Done.
