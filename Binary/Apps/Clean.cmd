@echo off
setlocal

if exist *.com del *.com

setlocal & cd Tunes && call Clean || exit /b 1 & endlocal
