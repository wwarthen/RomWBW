:: This script will build hd1k_combo.img and its required dependencies.
::
:: If large.def exists, it will also build hd1k_large.img (and any missing slice images
:: referenced by large.def).

@echo off
setlocal

SETLOCAL EnableDelayedExpansion

copy hd1k_prefix.dat ..\..\Binary\ || exit /b

:: Build the floppy disk images that are dependencies of combo.def

PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 fd144_cpm22 || exit /b
PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 fd144_zsdos || exit /b
PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 fd144_nzcom || exit /b
PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 fd144_cpm3 || exit /b
PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 fd144_zpm3 || exit /b
PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 fd144_ws4 || exit /b

:: Build only the hard disk slice images required for hd1k_combo.img
:: (based on combo.def: cpm22, zsdos, nzcom, cpm3, zpm3, wp)

PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 hd1k_cpm22 || exit /b
PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 hd1k_zsdos || exit /b
PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 hd1k_nzcom || exit /b
PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 hd1k_cpm3 || exit /b
PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 hd1k_zpm3 || exit /b
PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 hd1k_wp || exit /b

:: Build the hd1k_combo.img aggregate disk image

PowerShell -ExecutionPolicy Unrestricted .\BuildDsk.ps1 hd1k_combo || exit /b

:: Optionally build an additional aggregate image, if requested.
:: This keeps the default build fast, but ensures your custom aggregate is built
:: whenever the definition file is present.

if exist large.def (
  echo.
  echo ============================================================
  echo Building hd1k_large.img (from large.def)
  echo ============================================================
  echo.

  PowerShell -ExecutionPolicy Unrestricted -Command "Get-Content .\large.def | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') } | Sort-Object -Unique | ForEach-Object { Write-Host ('Building slice hd1k_' + $_ + '...'); & .\BuildImg.ps1 ('hd1k_' + $_) }" || exit /b
  PowerShell -ExecutionPolicy Unrestricted .\BuildDsk.ps1 hd1k_large || exit /b
)

