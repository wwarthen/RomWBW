@echo off
setlocal

setlocal & pushd HBIOS && Powershell .\Build.ps1 %* & endlocal
