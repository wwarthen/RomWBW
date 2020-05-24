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

rem zx slr180 -xmuf/HF
rem zx mload25 XMUF=xmdm125,xmuf

zx slr180 -xmx/HF
zx mload25 XMX=xmdm125,xmx

rem set PROMPT=[Build] %PROMPT%
rem %comspec%

copy /Y XM.com ..\..\..\Binary\Apps\
rem copy /Y XMUF.com ..\..\..\Binary\Apps\
copy /Y XMX.com ..\..\..\Binary\Apps\

rem pause