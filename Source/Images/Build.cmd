@echo off
setlocal

SETLOCAL EnableDelayedExpansion

copy hd1k_prefix.dat ..\..\Binary\ || exit /b

for %%f in (fd_*.txt) do (
  set Image=%%~nf
  PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 fd144_!Image:fd_=! || exit /b
)

for %%f in (hd_*.txt) do (
  set Image=%%~nf
  PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 hd512_!Image:hd_=! || exit /b
  PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 hd1k_!Image:hd_=! || exit /b
)

for %%f in (*.def) do (
  PowerShell -ExecutionPolicy Unrestricted .\BuildDsk.ps1 hd512_%%~nf || exit /b
  PowerShell -ExecutionPolicy Unrestricted .\BuildDsk.ps1 hd1k_%%~nf || exit /b
)
