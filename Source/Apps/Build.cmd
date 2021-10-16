@echo off
setlocal

set TOOLS=../../Tools
set APPBIN=..\..\Binary\Apps

set PATH=%TOOLS%\tasm32;%TOOLS%\zx;%PATH%

set TASMTABS=%TOOLS%\tasm32

set ZXBINDIR=%TOOLS%/cpm/bin/
set ZXLIBDIR=%TOOLS%/cpm/lib/
set ZXINCDIR=%TOOLS%/cpm/include/

call :asm syscopy || exit /b
call :asm assign || exit /b
call :asm format || exit /b
call :asm talk || exit /b
call :asm mode || exit /b
call :asm rtc || exit /b
call :asm timer || exit /b
call :asm rtchb || exit /b

zx Z80ASM -SYSGEN/F || exit /b

zx MAC SURVEY.ASM -$PO || exit /b
zx MLOAD25 -SURVEY.COM=SURVEY.HEX || exit /b

pushd XM && call Build || exit /b & popd
pushd FDU && call Build || exit /b & popd
pushd Tune && call Build || exit /b & popd
pushd FAT && call Build || exit /b & popd
pushd Test && call Build || exit /b & popd
pushd ZMP && call Build || exit /b & popd
pushd ZMD && call Build || exit /b & popd

copy *.com %APPBIN%\ || exit /b

goto :eof

:asm
echo.
echo Building %1...
tasm -t80 -g3 -fFF %1.asm %1.com %1.lst || exit /b
goto :eof

:asm180
echo.
echo Building %1...
tasm -t180 -g3 -fFF %1.asm %1.com %1.lst || exit /b
goto :eof
