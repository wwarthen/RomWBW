@echo off
setlocal

pushd ZZRCC && call Build || exit /b & popd
