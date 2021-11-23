@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF -dWBW vgmplay.asm vgmplay.com vgmplay.lst || exit /b

copy /Y VGMPLAY.COM ..\..\..\Binary\Apps\ || exit /b
copy /Y Tunes\*.* ..\..\..\Binary\Apps\Tunes\ || exit /b