@echo off

set TOOLS=../../Tools

setlocal & cd .\Forth && call Build || exit /b 1 & endlocal

setlocal

PowerShell .\Build.ps1 %*
