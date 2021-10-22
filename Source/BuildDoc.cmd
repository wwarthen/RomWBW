@echo off
setlocal

pushd Doc && call Build || exit /b & popd
