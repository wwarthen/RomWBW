@echo off
setlocal

set TOOLS=..\..\Tools
set PATH=%TOOLS%\tasm32;%TOOLS%\zxcc;%PATH%
set TASMTABS=%TOOLS%\tasm32
set CPMDIR80=%TOOLS%/cpm/

call :build syscopy || exit /b
call :build assign || exit /b
call :build format || exit /b
call :build talk || exit /b
call :build mode || exit /b
call :build rtc || exit /b
call :build timer || exit /b
call :build sysgen || exit /b
call :build XM || exit /b
call :build FDU || exit /b
call :build Tune || exit /b
call :build FAT || exit /b
call :build Test || exit /b
call :build ZMP || exit /b
call :build ZMD || exit /b
call :build Dev || exit /b
call :build VGM || exit /b
call :build cpuspd || exit /b
call :build reboot || exit /b
call :build Survey || exit /b
call :build HTalk || exit /b
call :build BBCBASIC || exit /b
call :build copysl || exit /b
call :build slabel || exit /b
call :build ZDE || exit /b

goto :eof

:build
echo Building %1
pushd %1 && call Build || exit /b & popd
goto :eof
