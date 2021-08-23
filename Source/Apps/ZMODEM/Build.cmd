@echo off
setlocal

set TOOLS=..\..\..\Tools

set PATH=%TOOLS%\zx;%PATH%

set ZXBINDIR=%TOOLS%\cpm\bin\
set ZXLIBDIR=%TOOLS%\cpm\lib\
set ZXINCDIR=%TOOLS%\cpm\include\

zx Z80ASM -ZMO-RW01/H || exit /b
zx MLOAD25 -ZMP.COM=ZMPX.COM,ZMO-RW01 || exit /b

copy /Y zmp.com ..\..\..\Binary\Apps\ || exit /b
copy /Y *.ovr ..\..\..\Binary\Apps\ || exit /b
copy /Y *.hlp ..\..\..\Binary\Apps\ || exit /b
copy /Y zmp.doc ..\..\..\Doc\ || exit /b