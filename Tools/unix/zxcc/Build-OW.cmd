@echo off
setlocal

::
:: Edit WATCOM variable below as needed for your environment
::
set WATCOM=..\..\Tools\WATCOM2

set PATH=%WATCOM%\BINNT;%WATCOM%\BINW;%PATH%
set EDPATH=%WATCOM%\EDDAT
set INCLUDE=%WATCOM%\H;%WATCOM%\H\NT

copy config.h.windows config.h

cl /Fe"zxcc.exe" zxcc.c cpmdrv.c cpmglob.c cpmparse.c cpmredir.c drdos.c util.c track.c xlt.c zxbdos.c zxcbdos.c zxdbdos.c z80.c
if errorlevel 1 exit /b 255

cl /Fe"zxccdbg.exe" /DDEBUG zxcc.c cpmdrv.c cpmglob.c cpmparse.c cpmredir.c drdos.c util.c track.c xlt.c zxbdos.c zxcbdos.c zxdbdos.c z80.c
if errorlevel 1 exit /b 255

copy cpm\bios.bin .