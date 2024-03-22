@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF -dWBW tune.asm tune.com tune.lst || exit /b
tasm -t180 -g3 -fFF -dZX tune.asm tunezx.com tunezx.lst || exit /b
tasm -t180 -g3 -fFF -dMSX tune.asm tunemsx.com tunemsx.lst || exit /b

copy /Y tune*.com ..\..\..\Binary\Apps\ || exit /b
copy /Y Tunes\*.* ..\..\..\Binary\Apps\Tunes\ || exit /b