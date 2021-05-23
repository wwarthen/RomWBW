@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF i2cscan.asm i2cscan.com i2cscan.lst
tasm -t180 -g3 -fFF rtcds7.asm rtcds7.com rtcds7.lst

if errorlevel 1 goto :eof

copy /Y i2cscan*.com ..\..\..\Binary\Apps\
copy /Y rtcds7*.com ..\..\..\Binary\Apps\
