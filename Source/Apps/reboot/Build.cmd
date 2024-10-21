@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -g3 -fFF reboot.asm reboot.com reboot.lst || exit /b

copy /Y reboot.com ..\..\..\Binary\Apps\ || exit /b
