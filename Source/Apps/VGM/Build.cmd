@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF -dWBW vgmplay.asm vgmplay.com vgmplay.lst || exit /b
tasm -t180 -g3 -fFF -dWBW ym2612.asm ym2612.com ym2612.lst || exit /b

copy /Y vgmplay.com ..\..\..\Binary\Apps\ || exit /b
copy /Y Tunes\*.* ..\..\..\Binary\Apps\Tunes\ || exit /b
