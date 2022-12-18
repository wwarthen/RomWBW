@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF -dWBW vgmplay.asm vgmplay.com vgmplay.lst || exit /b
tasm -t180 -g3 -fFF -dWBW ymfmdemo.asm ymfmdemo.com ymfmdemo.lst || exit /b

copy /Y vgmplay.com ..\..\..\Binary\Apps\ || exit /b
copy /Y Tunes\*.vgm ..\..\..\Binary\Apps\Tunes\ || exit /b
