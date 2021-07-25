@echo off
setlocal

pushd HBIOS && call Build %* || exit /b & popd
