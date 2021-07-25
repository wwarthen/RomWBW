@echo off
setlocal

pushd ZZR && call Build || exit /b & popd
