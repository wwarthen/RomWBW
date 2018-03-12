@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\bst;%PATH%

call :bstc PropIO
call :bstc PropIO2
call :bstc ParPortProp

goto :eof

:bstc
echo.
echo Building %1...
bstc Spin\%1 -e -l
if errorlevel 1 goto :eof
move /Y %1.eeprom "..\..\Binary"
goto :eof
