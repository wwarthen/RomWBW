@echo off
setlocal

pushd Images && call Build || exit /b & popd