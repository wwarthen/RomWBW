@echo off
setlocal

pushd Prop && call Build || exit /b & popd
