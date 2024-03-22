@echo off
setlocal

pushd Z1RCC && call Build || exit /b & popd
