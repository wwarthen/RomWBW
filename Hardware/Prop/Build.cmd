@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\bst;%PATH%

call :bstc PropIO || goto :eof
call :bstc PropIO2 || goto :eof
call :bstc ParPortProp || goto :eof

goto :eof

:bstc
echo.
echo Building %1...
bstc Spin\%1 -e -l
goto :eof
