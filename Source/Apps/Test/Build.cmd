@echo off
setlocal

set TOOLS=../../../Tools
set APPBIN=..\..\Binary\Apps

set PATH=%TOOLS%\tasm32;%TOOLS%\zxcc;%PATH%

set TASMTABS=%TOOLS%\tasm32

set CPMDIR80=%TOOLS%/cpm/

pushd DMAmon && call Build || exit /b & popd
pushd tstdskng && call Build || exit /b & popd
pushd inttest && call Build || exit /b & popd
pushd ppidetst && call Build || exit /b & popd
pushd ramtest && call Build || exit /b & popd
pushd I2C && call Build || exit /b & popd
pushd rzsz && call Build || exit /b & popd
pushd vdctest && call Build || exit /b & popd
pushd kbdtest && call Build || exit /b & popd
pushd ps2info && call Build || exit /b & popd
pushd 2piotst && call Build || exit /b & popd
pushd piomon && call Build || exit /b & popd
pushd banktest && call Build || exit /b & popd
pushd portswp && call Build || exit /b & popd

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
