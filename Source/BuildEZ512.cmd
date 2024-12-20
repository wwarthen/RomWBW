@echo off
setlocal

pushd EZ512 && call Build || exit /b & popd
