@echo off
setlocal

pushd ZZRC && call Build || exit /b & popd
