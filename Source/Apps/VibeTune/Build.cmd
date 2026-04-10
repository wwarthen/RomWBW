@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -g3 -fFF -dWBW vibetune.asm vtune.com vtune.lst || exit /b
tasm -t80 -g3 -fFF -dZX vibetune.asm vtunezx.com vtunezx.lst || exit /b
tasm -t80 -g3 -fFF -dMSX vibetune.asm vtunemsx.com vtunemsx.lst || exit /b

copy /Y vtune*.com ..\..\..\Binary\Apps\ || exit /b
copy /Y Tunes\*.* ..\..\..\Binary\Apps\Tunes\ || exit /b