@echo off
setlocal

pushd BPBIOS && call Build || exit /b & popd