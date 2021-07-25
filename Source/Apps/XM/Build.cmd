@echo off
setlocal

set TOOLS=..\..\..\Tools

set PATH=%TOOLS%\zx;%PATH%

set ZXBINDIR=%TOOLS%\cpm\bin\
set ZXLIBDIR=%TOOLS%\cpm\lib\
set ZXINCDIR=%TOOLS%\cpm\include\

zx mac xmdm125.asm $PO || exit /b

zx slr180 -xmhb/HF || exit /b
zx mload25 XM=xmdm125,xmhb || exit /b

rem zx slr180 -xmuf/HF || exit /b
rem zx mload25 XMUF=xmdm125,xmuf || exit /b

zx slr180 -xmhb_old/HF || exit /b
zx mload25 XMOLD=xmdm125,xmhb_old || exit /b

rem set PROMPT=[Build] %PROMPT%
rem %comspec%

copy /Y XM.com ..\..\..\Binary\Apps\ || exit /b
rem copy /Y XMUF.com ..\..\..\Binary\Apps\ || exit /b
copy /Y XMOLD.com ..\..\..\Binary\Apps\ || exit /b

rem pause