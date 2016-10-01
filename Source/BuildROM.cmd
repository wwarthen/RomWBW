@echo off
setlocal

setlocal & cd HBIOS && Powershell .\Build.ps1 %* || exit /b 1 & endlocal
