@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF Tune.asm Tune.com Tune.lst

if errorlevel 1 goto :eof

copy /Y Tune.com ..\..\..\Binary\Apps\
copy /Y Tunes\*.* ..\..\..\Binary\Apps\Tunes\