:: This script will build all slice images and all aggregate disk
:: images.

@echo off
setlocal

SETLOCAL EnableDelayedExpansion

copy hd1k_prefix.dat ..\..\Binary\ || exit /b

:: For each floppy disk image definition (fd_*.txt), invoke PowerShell
:: to build the image.

for %%f in (fd_*.txt) do (
  set Image=%%~nf
  PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 fd144_!Image:fd_=! || exit /b
)

:: For each hard disk slice image definition (hd_*.txt), invoke
:: PowerShell to build the slice image.  Note that both hd512 and
:: hd1k style images are built.

for %%f in (hd_*.txt) do (
  set Image=%%~nf
  PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 hd512_!Image:hd_=! || exit /b
  PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 hd1k_!Image:hd_=! || exit /b
)

:: For each aggregate disk image definition (*.def), invoke PowerShell
:: to build the disk image.

for %%f in (*.def) do (
  PowerShell -ExecutionPolicy Unrestricted .\BuildDsk.ps1 hd512_%%~nf || exit /b
  PowerShell -ExecutionPolicy Unrestricted .\BuildDsk.ps1 hd1k_%%~nf || exit /b
)

