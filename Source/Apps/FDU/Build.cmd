@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -b -fFF fdu.asm fdu.com fdu.lst

if errorlevel 1 goto :eof

copy /Y fdu.com ..\..\..\Binary\Apps\
copy /Y fdu.txt ..\..\..\Doc\