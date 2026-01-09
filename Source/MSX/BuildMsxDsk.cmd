:: This script will build an aggregate MSX disk image

@echo off
setlocal

SETLOCAL EnableDelayedExpansion

set MTOOLS_SKIP_CHECK=1
set TOOLS=../../Tools
set PATH=%TOOLS%\mtools;%PATH%

PowerShell -ExecutionPolicy Unrestricted .\BuildMsxDsk.ps1 || exit /b

