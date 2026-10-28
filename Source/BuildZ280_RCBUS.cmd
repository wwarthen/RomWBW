@echo off
setlocal

pushd Z280_RCBUS && call Build || exit /b & popd
