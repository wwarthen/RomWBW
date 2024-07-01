@echo off
setlocal

pushd FZ80 && call Build || exit /b & popd
