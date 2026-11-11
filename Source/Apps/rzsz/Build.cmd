@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

:: release build, statistics temporarily enabled
tasm -t80 -g3 -fFF rz.asm rz.com rz.lst || exit /b
tasm -t80 -g3 -fFF sz.asm sz.com sz.lst || exit /b

:: build of original code for reference
tasm -t80 -g3 -fFF rz_orig.asm rz_orig.com rz_orig.lst || exit /b
tasm -t80 -g3 -fFF sz_orig.asm sz_orig.com sz_orig.lst || exit /b

:: diagnostic build with statistics enabled
tasm -t80 -g3 -fFF -dCFG_RXSTATS=1 rz.asm rzstats.com rzstats.lst || exit /b
tasm -t80 -g3 -fFF -dCFG_TXSTATS=1 sz.asm szstats.com szstats.lst || exit /b

:: diagnostic builds with block mode disabled
tasm -t80 -g3 -fFF -dCFG_BLKIO=0 -dCFG_RXSTATS=0 rz.asm rzbyte.com rzbyte.lst || exit /b
tasm -t80 -g3 -fFF -dCFG_BLKIO=0 -dCFG_TXSTATS=0 sz.asm szbyte.com szbyte.lst || exit /b

copy /Y rz.com ..\..\..\Binary\Apps\ || exit /b
copy /Y sz.com ..\..\..\Binary\Apps\ || exit /b
