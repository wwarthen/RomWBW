@echo off
setlocal

set TOOLS=../../../../Tools
set PATH=%TOOLS%\zxcc;%PATH%

set HITECHDIR=../../../Images/d_hitechc/u0/
set BINDIR80=%HITECHDIR%
set LIBDIR80=%HITECHDIR%
set INCDIR80=%HITECHDIR%

zxcc C --C --N rndtest.c || exit /b
zxcc C --C --N hbio.c || exit /b
zxcc C --V --N rndtest.obj hbio.obj || exit /b

copy /Y rndtest.com ..\..\..\..\Binary\Apps\Test\ || exit /b
