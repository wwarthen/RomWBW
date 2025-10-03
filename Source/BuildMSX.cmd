@echo off
setlocal

pushd MSX && call Build || exit /b & popd
