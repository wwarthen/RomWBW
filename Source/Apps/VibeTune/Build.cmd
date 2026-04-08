@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t80 -g3 -fFF -dWBW vibetune.asm vibetune.com vibetune.lst || exit /b
tasm -t80 -g3 -fFF -dZX vibetune.asm vibetunezx.com vibetunezx.lst || exit /b
tasm -t80 -g3 -fFF -dMSX vibetune.asm vibetunemsx.com vibetunemsx.lst || exit /b

copy /Y vibetune*.com ..\..\..\Binary\Apps\ || exit /b
copy /Y Tunes\*.* ..\..\..\Binary\Apps\Tunes\ || exit /b