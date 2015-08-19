@echo off
setlocal

pushd HBIOS && Powershell .\Build.ps1 %* && popd
