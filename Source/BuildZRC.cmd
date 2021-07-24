@echo off
setlocal

pushd ZRC && call Build || exit /b & popd
