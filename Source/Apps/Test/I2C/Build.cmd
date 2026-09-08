@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -g3 -fFF i2cscecb.asm i2cscecb.com i2cscecb.lst || exit /b
tasm -t80 -g3 -fFF i2cscduo.asm i2cscduo.com i2cscduo.lst || exit /b
tasm -t80 -g3 -fFF i2cscpyc.asm i2cscpyc.com i2cscpyc.lst || exit /b
tasm -t80 -g3 -fFF i2cscp8x.asm i2cscp8x.com i2cscp8x.lst || exit /b
tasm -t80 -g3 -fFF i2csc126.asm i2csc126.com i2csc126.lst || exit /b
tasm -t80 -g3 -fFF i2csc137.asm i2csc137.com i2csc137.lst || exit /b
tasm -t80 -g3 -fFF pcfstat.asm pcfstat.com pcfstat.lst || exit /b
tasm -t80 -g3 -fFF rtcds7.asm rtcds7.com rtcds7.lst || exit /b
tasm -t80 -g3 -fFF i2clcd.asm i2clcd.com i2clcd.lst || exit /b
tasm -t80 -g3 -ff srom.asm srom.com srom.lst || exit /b

copy /Y *.com ..\..\..\..\Binary\Apps\Test\ || exit /b
