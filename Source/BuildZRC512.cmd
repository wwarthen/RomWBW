@echo off
setlocal

pushd ZRC512 && call Build || exit /b & popd
