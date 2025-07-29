@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\lzsa;%TOOLS%\fonttool;%PATH%

echo.
echo Preparing compressed font files...

for %%f in (font6x8 font8x8 font8x11 font8x16) do call :genfont %%f

goto :eof

:genfont
echo Processing font %1...
lzsa -f2 -r %1u.bin %1c.bin || exit /b
fonttool %1u.bin >%1u.asm || exit /b
fonttool %1c.bin >%1c.asm || exit /b

goto :eof
