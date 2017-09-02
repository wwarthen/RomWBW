@echo off
setlocal

if exist *.bin del *.bin
if exist *.com del *.com
if exist *.lst del *.lst

setlocal & cd XM && call Clean || exit /b 1 & endlocal
setlocal & cd FDU && call Clean || exit /b 1 & endlocal
