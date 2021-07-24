@echo off
setlocal

rem pushd HBIOS && Powershell -ExecutionPolicy Unrestricted .\Build.ps1 %* || exit /b & popd

pushd HBIOS && call Build %* || exit /b & popd
