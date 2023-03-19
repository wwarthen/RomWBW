@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -b -f00 rz.asm rz.com rz.lst || exit /b
tasm -t80 -b -f00 sz.asm sz.com sz.lst || exit /b

:: Compare to original distribution
:: Need to remove these lines when starting to make actual changes
fc /B rz.com rz.com.orig || exit /b
fc /B sz.com sz.com.orig || exit /b

copy /Y rz.com ..\..\..\..\Binary\Apps\Test\ || exit /b
copy /Y sz.com ..\..\..\..\Binary\Apps\Test\ || exit /b
