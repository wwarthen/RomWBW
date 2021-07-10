@echo off
setlocal

set TOOLS=../../Tools
set APPBIN=..\..\Binary\Apps

set PATH=%TOOLS%\tasm32;%TOOLS%\zx;%PATH%

set TASMTABS=%TOOLS%\tasm32

set ZXBINDIR=%TOOLS%/cpm/bin/
set ZXLIBDIR=%TOOLS%/cpm/lib/
set ZXINCDIR=%TOOLS%/cpm/include/

call :asm syscopy || goto :eof
call :asm assign || goto :eof
call :asm format || goto :eof
call :asm talk || goto :eof
call :asm mode || goto :eof
call :asm rtc || goto :eof
call :asm timer || goto :eof
call :asm180 inttest || goto :eof
call :asm rtcds7 || goto :eof
call :asm rtchb || goto :eof
call :asm ppidetst || goto :eof
call :asm tstdskng || goto :eof

zx Z80ASM -SYSGEN/F

zx MAC SURVEY.ASM -$PO
zx MLOAD25 -SURVEY.COM=SURVEY.HEX

setlocal & cd XM && call Build || exit /b 1 & endlocal
setlocal & cd FDU && call Build || exit /b 1 & endlocal
setlocal & cd Tune && call Build || exit /b 1 & endlocal
setlocal & cd FAT && call Build || exit /b 1 & endlocal

copy *.com %APPBIN%\

goto :eof

:asm
echo.
echo Building %1...
tasm -t80 -g3 -fFF %1.asm %1.com %1.lst
goto :eof

:asm180
echo.
echo Building %1...
tasm -t180 -g3 -fFF %1.asm %1.com %1.lst
goto :eof
