@echo off
pushd Source
PowerShell .\Build.ps1 %*
popd