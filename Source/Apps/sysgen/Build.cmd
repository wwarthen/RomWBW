@echo off
setlocal

set TOOLS=..\..\..\Tools
set PATH=%TOOLS%\tasm32;%TOOLS%\zxcc;%PATH%
set TASMTABS=%TOOLS%\tasm32
set CPMDIR80=%TOOLS%/cpm/

:: tasm -t80 -g3 -fFF sysgen.asm sysgen.com sysgen.lst || exit /b

zxcc Z80ASM -SYSGEN/F || exit /b

copy /Y sysgen.com ..\..\..\Binary\Apps\ || exit /b
