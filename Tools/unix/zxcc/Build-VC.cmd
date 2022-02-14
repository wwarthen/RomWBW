@echo off
setlocal

::
:: Visual Studio x86 Native Tools Command Prompt is assumed
::

:: Below configures VS2012 to target Windows XP.
:: Not sure if it will work in later versions of VS, but seems
:: to do no harm.
set INCLUDE=%ProgramFiles(x86)%\Microsoft SDKs\Windows\7.1A\Include;%INCLUDE%
set PATH=%ProgramFiles(x86)%\Microsoft SDKs\Windows\7.1A\Bin;%PATH%
set LIB=%ProgramFiles(x86)%\Microsoft SDKs\Windows\7.1A\Lib;%LIB%
set CL=/D_USING_V110_SDK71_;%CL%
set LINK=/SUBSYSTEM:CONSOLE,5.01 %LINK%

copy config.h.windows config.h

cl -I. zxcc.c cpmdrv.c cpmglob.c cpmparse.c cpmredir.c drdos.c util.c xlt.c zxbdos.c zxcbdos.c zxdbdos.c z80.c dirent.c track.c
if errorlevel 1 exit /b 255

cl -I. /DDEBUG /Fe"zxccdbg.exe" zxcc.c cpmdrv.c cpmglob.c cpmparse.c cpmredir.c drdos.c util.c xlt.c zxbdos.c zxcbdos.c zxdbdos.c z80.c dirent.c track.c
if errorlevel 1 exit /b 255

copy cpm\bios.bin .