@echo off
setlocal

set TOOLS=..\..\..\Tools

set PATH=%TOOLS%\zx;%PATH%

set ZXBINDIR=%TOOLS%\cpm\bin\
set ZXLIBDIR=%TOOLS%\cpm\lib\
set ZXINCDIR=%TOOLS%\cpm\include\

zx mac xmdm125.asm $PO
zx slr180 -xmhb/HF
zx mload25 XM=xmdm125,xmhb

rem set PROMPT=[Build] %PROMPT%
rem %comspec%

move /Y XM.com ..
