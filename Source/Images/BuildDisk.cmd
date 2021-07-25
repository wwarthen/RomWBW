@echo off
setlocal

PowerShell -ExecutionPolicy Unrestricted .\BuildDisk.ps1 %* || exit /b