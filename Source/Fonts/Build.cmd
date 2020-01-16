@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\lzsa;%TOOLS%\fonttool;%PATH%

echo.
echo Preparing compressed font files...

lzsa -f2 -r font8x8u.bin font8x8c.bin
lzsa -f2 -r font8x11u.bin font8x11c.bin
lzsa -f2 -r font8x16u.bin font8x16c.bin

fonttool font8x8u.bin > font8x8u.asm
fonttool font8x11u.bin > font8x11u.asm
fonttool font8x16u.bin > font8x16u.asm
fonttool font8x8c.bin > font8x8c.asm
fonttool font8x11c.bin > font8x11c.asm
fonttool font8x16c.bin > font8x16c.asm
