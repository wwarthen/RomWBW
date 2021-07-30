@echo off
setlocal

pushd Binary && call Clean || exit /b 1 & popd
pushd Source && call Clean || exit /b 1 & popd
