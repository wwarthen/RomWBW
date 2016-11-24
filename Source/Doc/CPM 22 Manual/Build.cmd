@echo off
setlocal

set TOOLS=..\..\..\Tools

set PATH=%TOOLS%\zx;%PATH%

set ZXBINDIR=%TOOLS%/cpm/bin/
set ZXLIBDIR=%TOOLS%/cpm/lib/
set ZXINCDIR=%TOOLS%/cpm/include/

rem set TEXOPT=-$D -$Q

zx TEX21A PART1 %TEXOPT%
zx TEX21A PART2 %TEXOPT%
zx TEX21A PART3 %TEXOPT%

echo Remove extraneous control codes and escape sequences
rem pause

PowerShell .\Strip.ps1

call texify -p --clean "Main.ltx"

if errorlevel 1 goto :eof

move /Y Main.pdf "..\..\..\Doc\CPM 22 Manual.pdf"