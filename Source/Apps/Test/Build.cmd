@echo off
setlocal

set TOOLS=../../../Tools
set APPBIN=..\..\Binary\Apps

set PATH=%TOOLS%\tasm32;%TOOLS%\zx;%PATH%

set TASMTABS=%TOOLS%\tasm32

set ZXBINDIR=%TOOLS%/cpm/bin/
set ZXLIBDIR=%TOOLS%/cpm/lib/
set ZXINCDIR=%TOOLS%/cpm/include/

pushd DMAmon && call Build || exit /b & popd
pushd tstdskng && call Build || exit /b & popd
pushd inttest && call Build || exit /b & popd
pushd ppidetst && call Build || exit /b & popd
pushd ramtest && call Build || exit /b & popd
pushd I2C && call Build || exit /b & popd
pushd rzsz && call Build || exit /b & popd

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
