@echo off
setlocal

set TOOLS=..\..\..\Tools

set PATH=%TOOLS%\tasm32;%PATH%

set TASMTABS=%TOOLS%\tasm32

:: git@github.com:dimitrit/tastybasic.git; commit a86d7e7; (HEAD -> master, tag: v0.3.0) 
set VER=v0.3.0

tasm -80 -g3 -fFF -dROMWBW -d"VERSION \"%VER%\"" tastybasic.asm tastybasic.bin tastybasic.bin.lst
tasm -80 -g3 -fFF -dCPM -d"VERSION \"%VER%\"" tastybasic.asm tastybasic.com tastybasic.com.lst

copy /b /v tastybasic.com tbasic.com
copy /b /v tbasic.com ..\..\..\Binary\Apps\tbasic.com
