@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -b -fFF FDU.asm FDU.com FDU.lst

if errorlevel 1 goto :eof

copy /Y FDU.com ..\..\..\Binary\Apps\
copy /Y FDU.txt ..\..\..\Doc\