@echo off
setlocal

set TOOLS=..\..\..\Tools
set TASM=%TOOLS%\tasm32\tasm.exe

echo Building aytest.com...
%TASM% -80 -b aytest.asm aytest.com aytest.lst

if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

echo.
echo Build successful! aytest.com created.
echo.
echo To test your second AY chip at E0/E1, copy aytest.com to your RC2014 and run it.
echo You should hear a 3-note chord (A-C-E) for about 2 seconds.
