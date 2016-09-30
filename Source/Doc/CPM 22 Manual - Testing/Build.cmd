@echo off
setlocal

set TOOLS=..\..\..\Tools

set PATH=%TOOLS%\zx;%PATH%

set ZXBINDIR=%TOOLS%/cpm/bin/
set ZXLIBDIR=%TOOLS%/cpm/lib/
set ZXINCDIR=%TOOLS%/cpm/include/

set TEXOPT=-$D

zx TEX21 PART1 %TEXOPT%
zx TEX21 PART2 %TEXOPT%
zx TEX21 PART3 %TEXOPT%

echo Remove extraneous control codes and escape sequences
rem pause

PowerShell .\Strip.ps1

call texify -p --clean "Main.ltx"