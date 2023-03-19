@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zxcc;%PATH%

set TASMTABS=%TOOLS%\tasm32

set CPMDIR80=%TOOLS%/cpm/

zxcc ZMAC -ZSDOS -/P || exit /b
zxcc LINK -ZSDOS.BIN=ZSDOS[LD800] || exit /b

tasm -t80 -g3 -fFF loader.asm loader.bin loader.lst || exit /b

copy /b ..\zcpr-dj\zcpr.bin + zsdos.bin + ..\cbios\cbios_wbw.bin zsys_wbw.bin || exit /b
copy /b ..\zcpr-dj\zcpr.bin + zsdos.bin + ..\cbios\cbios_una.bin zsys_una.bin || exit /b

copy /b loader.bin + zsys_wbw.bin zsys_wbw.sys || exit /b
copy /b loader.bin + zsys_una.bin zsys_una.sys || exit /b
