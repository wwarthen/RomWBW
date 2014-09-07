@echo off
setlocal

pushd BIOS && Powershell .\Build.ps1 %* && popd
