@echo off
setlocal

for %%f in (*.def) do (
  PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 %%~nf || exit /b
)
