@echo off
setlocal

set TOOLS=../../Tools
set BIN=..\..\Binary

set PATH=%TOOLS%\tasm32;%PATH%

set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF -DAPPBOOT hdiag.asm hdiag.com hdiag_com.lst || exit /b
tasm -t180 -g3 -fFF -DROMBOOT hdiag.asm hdiag.rom hdiag_rom.lst || exit /b

copy hdiag.rom %BIN% || exit /b
copy hdiag.com %BIN% || exit /b
