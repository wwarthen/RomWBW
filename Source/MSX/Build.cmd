@echo off
setlocal

::
:: Build MSX loader
::

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zxcc;%PATH%

set TASMTABS=%TOOLS%\tasm32

set CPMDIR80=%TOOLS%/cpm/

tasm -t80 -g3 msx-ldr.asm msx-ldr.com msx-ldr.lst || exit /b

if exist msx-ldr.com copy msx-ldr.com ..\..\Binary\ || exit /b
