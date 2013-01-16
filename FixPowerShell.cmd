@echo off
echo Setting PowerShell ExecutionPolicy = RemoteSigned...
echo.
PowerShell Set-ExecutionPolicy RemoteSigned
echo PowerShell ExecutionPolicy is now:
PowerShell Get-ExecutionPolicy
echo.
echo The execution policy should be "RemoteSigned"
echo.
pause