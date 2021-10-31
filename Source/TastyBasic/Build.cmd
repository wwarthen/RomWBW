@echo off
setlocal

pushd src && call Build || exit /b & popd
