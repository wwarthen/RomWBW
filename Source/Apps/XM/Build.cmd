@echo off
setlocal

set TOOLS=..\..\..\Tools

set PATH=%TOOLS%\zxcc;%PATH%

set CPMDIR80=%TOOLS%/cpm/

:: XModem core
zxcc mac xmdm125.asm $PO || exit /b

:: Current build (FastPath + Block I/O)
zxcc slr180 -xmhb/HF || exit /b
zxcc mload25 XM=xmdm125,xmhb || exit /b
copy /Y XM.com ..\..\..\Binary\Apps\ || exit /b

:: USB-FIFO specific build
::zxcc slr180 -xmuf/HF || exit /b
::zxcc mload25 XMUF=xmdm125,xmuf || exit /b

:: Original HBIOS build
::zxcc slr180 -xmhb_old/HF || exit /b
::zxcc mload25 XMOLD=xmdm125,xmhb_old || exit /b

:: HBIOS w/ FastPath build
::zxcc slr180 -xmhb_fp/HF || exit /b
::zxcc mload25 XMFP=xmdm125,xmhb_fp || exit /b
