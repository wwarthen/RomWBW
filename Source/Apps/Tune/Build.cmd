@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF -dWBW Tune.asm Tune.com Tune.lst
tasm -t180 -g3 -fFF -dZX Tune.asm Tunezx.com Tunezx.lst
tasm -t180 -g3 -fFF -dMSX Tune.asm Tunemsx.com Tunemsx.lst

if errorlevel 1 goto :eof

copy /Y Tune*.com ..\..\..\Binary\Apps\
copy /Y Tunes\*.* ..\..\..\Binary\Apps\Tunes\