@echo off
setlocal

if exist *.bin del *.bin
if exist *.dat del *.dat
if exist *.com del *.com
if exist *.img del *.img
if exist *.rom del *.rom
if exist *.pdf del *.pdf
if exist *.log del *.log
if exist *.eeprom del *.eeprom

setlocal & cd Apps && call Clean || exit /b 1 & endlocal
setlocal & cd CPM3 && call Clean || exit /b 1 & endlocal
setlocal & cd ZPM3 && call Clean || exit /b 1 & endlocal
