@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF -dWBW tune.asm tune.com tune.lst
tasm -t180 -g3 -fFF -dZX tune.asm tunezx.com tunezx.lst
tasm -t180 -g3 -fFF -dMSX tune.asm tunemsx.com tunemsx.lst

if errorlevel 1 goto :eof

copy /Y tune*.com ..\..\..\Binary\Apps\
copy /Y Tunes\*.* ..\..\..\Binary\Apps\Tunes\