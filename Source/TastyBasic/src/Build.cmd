@echo off
setlocal

set TOOLS=..\..\..\Tools

set PATH=%TOOLS%\tasm32;%PATH%

set TASMTABS=%TOOLS%\tasm32

tasm -80 -dROMWBW tastybasic.asm tastybasic.bin tastybasic.bin.lst
tasm -80 -dCPM tastybasic.asm tastybasic.com tastybasic.com.lst

copy /b /v tastybasic.com ..\..\..\Binary\Apps\tbasic.com
