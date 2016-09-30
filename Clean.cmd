@echo off

setlocal

setlocal & pushd Source && call Clean & endlocal
setlocal & pushd Images && call Clean & endlocal
setlocal & pushd Hardware && call Clean & endlocal
setlocal & pushd Output && call Clean & endlocal

if exist *.img del *.img
if exist *.log del *.log