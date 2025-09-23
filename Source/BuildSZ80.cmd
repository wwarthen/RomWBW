@echo off
setlocal

pushd SZ80 && call Build || exit /b & popd
