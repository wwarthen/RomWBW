@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zxcc;%PATH%

set TASMTABS=%TOOLS%\tasm32

set CPMDIR80=%TOOLS%/cpm/

tasm -t80 -g3 -fFF loader.asm loader.bin loader.lst || exit /b

copy /b qcp27.dat + qdos27.dat + ..\cbios\cbios_wbw.bin qpm_wbw.bin || exit /b
copy /b qcp27.dat + qdos27.dat + ..\cbios\cbios_una.bin qpm_una.bin || exit /b

copy /b loader.bin + qpm_wbw.bin qpm_wbw.sys || exit /b
copy /b loader.bin + qpm_una.bin qpm_una.sys || exit /b

rem Copy OS files to Binary directory
copy qpm_wbw.sys ..\..\Binary\QPM || exit /b
copy qpm_una.sys ..\..\Binary\QPM || exit /b

goto :eof
