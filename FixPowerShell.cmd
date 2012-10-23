@echo off
echo Setting PowerShell ExecutionPolicy = Unrestricted...
echo.
PowerShell Set-ExecutionPolicy Unrestricted
echo PowerShell ExecutionPolicy is now:
PowerShell Get-ExecutionPolicy
echo.
echo The execution policy should be "Unrestricted"
echo.
pause