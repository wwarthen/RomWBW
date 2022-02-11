@echo off
setlocal

set TOOLS=..\..\..\Tools

set PATH=%TOOLS%\zxcc;%PATH%

set CPMDIR80=%TOOLS%/cpm/

zxcc Z80ASM -ZMO-RW01/H || exit /b
zxcc MLOAD25 -ZMP.COM=ZMPX.COM,ZMO-RW01 || exit /b

copy /Y zmp.com ..\..\..\Binary\Apps\ || exit /b
copy /Y *.ovr ..\..\..\Binary\Apps\ || exit /b
copy /Y *.hlp ..\..\..\Binary\Apps\ || exit /b
copy /Y zmp.doc ..\..\..\Binary\Apps\ || exit /b