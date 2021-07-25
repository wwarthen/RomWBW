@echo off
setlocal

if exist *.bin del *.bin
if exist *.com del *.com
if exist *.lst del *.lst
if exist *.hex del *.hex
if exist *.prn del *.prn

pushd XM && call Clean || exit /b 1 & popd
pushd FDU && call Clean || exit /b 1 & popd
pushd Tune && call Clean || exit /b 1 & popd
pushd FAT && call Clean || exit /b 1 & popd
pushd I2C && call Clean || exit /b 1 & popd
pushd ramtest && call Clean || exit /b 1 & popd
