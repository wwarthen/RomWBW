@echo off
setlocal

set TOOLS=../../Tools

PowerShell -ExecutionPolicy Unrestricted .\Build.ps1 %* || exit /b
