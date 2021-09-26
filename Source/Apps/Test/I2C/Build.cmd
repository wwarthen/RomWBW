@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF i2cscan.asm i2cscan.com i2cscan.lst || exit /b
tasm -t180 -g3 -fFF rtcds7.asm rtcds7.com rtcds7.lst || exit /b
tasm -t180 -g3 -fFF i2clcd.asm i2clcd.com i2clcd.lst || exit /b

copy /Y i2c*.com ..\..\..\..\Binary\Apps\Test\ || exit /b
copy /Y rtcds7*.com ..\..\..\..\Binary\Apps\Test\ || exit /b
