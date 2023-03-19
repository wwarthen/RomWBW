@echo off
setlocal

pushd Source && call Build %* || exit /b & popd

if "%*" == "" pause
