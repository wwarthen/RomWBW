@echo off
setlocal

set TOOLS=..\..\..\Tools

set PATH=%TOOLS%\zxcc;%PATH%

set CPMDIR80=%TOOLS%/cpm/

:: zxcc Z80ASM -ZMO-RW01/LH || exit /b
zxcc Z80ASM -ZMO-WBW/LH || exit /b
zxcc MLOAD25 -ZMP.COM=ZMPX.COM,ZMO-WBW || exit /b

copy /Y zmp.com ..\..\..\Binary\Apps\ || exit /b
copy /Y *.ovr ..\..\..\Binary\Apps\ || exit /b
copy /Y zmp.cfg ..\..\..\Binary\Apps\ || exit /b
copy /Y zmp.fon ..\..\..\Binary\Apps\ || exit /b
copy /Y *.hlp ..\..\..\Binary\Apps\ || exit /b
copy /Y zmp.doc ..\..\..\Binary\Apps\ || exit /b