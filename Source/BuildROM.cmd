@echo off
setlocal

setlocal & cd HBIOS && Powershell -ExecutionPolicy Unrestricted .\Build.ps1 %* || exit /b 1 & endlocal
