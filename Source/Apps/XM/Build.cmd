@echo off
setlocal

set TOOLS=..\..\..\Tools

set PATH=%TOOLS%\zxcc;%PATH%

set CPMDIR80=%TOOLS%/cpm/

zxcc mac xmdm125.asm $PO || exit /b

zxcc slr180 -xmhb/HF || exit /b
zxcc mload25 XM=xmdm125,xmhb || exit /b

rem zxcc slr180 -xmuf/HF || exit /b
rem zxcc mload25 XMUF=xmdm125,xmuf || exit /b

zxcc slr180 -xmhb_old/HF || exit /b
zxcc mload25 XMOLD=xmdm125,xmhb_old || exit /b

rem set PROMPT=[Build] %PROMPT%
rem %comspec%

copy /Y XM.com ..\..\..\Binary\Apps\ || exit /b
rem copy /Y XMUF.com ..\..\..\Binary\Apps\ || exit /b
copy /Y XMOLD.com ..\..\..\Binary\Apps\ || exit /b

rem pause