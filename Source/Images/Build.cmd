:: This script will build only hd1k_combo.img and its required dependencies.
::

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
:: (based on combo.def: cpm22, zsdos, nzcom, cpm3, zpm3, ws4)

PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 hd1k_cpm22 || exit /b
PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 hd1k_zsdos || exit /b
PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 hd1k_nzcom || exit /b
PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 hd1k_cpm3 || exit /b
PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 hd1k_zpm3 || exit /b
PowerShell -ExecutionPolicy Unrestricted .\BuildImg.ps1 hd1k_wp || exit /b

:: Build only the hd1k_combo.img aggregate disk image

PowerShell -ExecutionPolicy Unrestricted .\BuildDsk.ps1 hd1k_combo || exit /b

