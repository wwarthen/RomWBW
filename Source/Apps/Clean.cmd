@echo off
setlocal

if exist *.bin del *.bin
if exist *.com del *.com
if exist *.lst del *.lst
if exist *.hex del *.hex
if exist *.prn del *.prn

setlocal & cd XM && call Clean || exit /b 1 & endlocal
setlocal & cd FDU && call Clean || exit /b 1 & endlocal
setlocal & cd Tune && call Clean || exit /b 1 & endlocal
setlocal & cd FAT && call Clean || exit /b 1 & endlocal
