@echo off
setlocal

set TOOLS=..\..\..\Tools
set PATH=%TOOLS%\tasm32;%TOOLS%\zxcc;%PATH%
set TASMTABS=%TOOLS%\tasm32
set CPMDIR80=%TOOLS%/cpm/

call :build DMAmon || exit /b
call :build tstdskng || exit /b
call :build inttest || exit /b
call :build ppidetst || exit /b
call :build ramtest || exit /b
call :build I2C || exit /b
call :build rzsz || exit /b
call :build vdctest || exit /b
call :build kbdtest || exit /b
call :build ps2info || exit /b
call :build 2piotst || exit /b
call :build piomon || exit /b
call :build banktest || exit /b
call :build portscan || exit /b
call :build sound || exit /b
call :build testh8p || exit /b

goto :eof

:build
echo Building %1
pushd %1 && call Build || exit /b & popd
goto :eof
