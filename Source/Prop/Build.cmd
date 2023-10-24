@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\OpenSpin;%PATH%

call :openspin PropIO
call :openspin PropIO2
call :openspin ParPortProp

goto :eof

:openspin
echo.
echo Building %1...
openspin -e Spin\%1.spin || exit /b
move /Y Spin\%1.eeprom "..\..\Binary" || exit /b
goto :eof
