@echo off
setlocal

pushd Source && call Build %* || exit /b & popd

pause
