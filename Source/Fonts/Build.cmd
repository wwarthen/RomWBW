@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\lzsa;%TOOLS%\fonttool;%PATH%

echo.
echo Preparing compressed font files...

lzsa -f2 -r font8x8u.bin font8x8c.bin || exit /b
lzsa -f2 -r font8x11u.bin font8x11c.bin || exit /b
lzsa -f2 -r font8x16u.bin font8x16c.bin || exit /b

lzsa -f2 -r fontcgau.bin fontcgac.bin || exit /b

fonttool font8x8u.bin > font8x8u.asm || exit /b
fonttool font8x11u.bin > font8x11u.asm || exit /b
fonttool font8x16u.bin > font8x16u.asm || exit /b
fonttool font8x8c.bin > font8x8c.asm || exit /b
fonttool font8x11c.bin > font8x11c.asm || exit /b
fonttool font8x16c.bin > font8x16c.asm || exit /b

fonttool fontcgau.bin > fontcgau.asm || exit /b
fonttool fontcgac.bin > fontcgac.asm || exit /b
