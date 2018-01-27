@echo off
setlocal

set TOOLS=../../../Tools
set PATH=%TOOLS%\tasm32;%PATH%
set TASMTABS=%TOOLS%\tasm32

tasm -t180 -g3 -fFF PTxPlay.asm PTxPlay.com PTxPlay.lst

if errorlevel 1 goto :eof

copy /Y PTxPlay.com ..\..\..\Binary\Apps\
copy /Y Tunes\*.pt3 ..\..\..\Binary\Apps\Tunes\