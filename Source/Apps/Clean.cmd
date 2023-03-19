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
pushd Test && call Clean || exit /b 1 & popd
pushd ZMP && call Clean || exit /b 1 & popd
pushd ZMD && call Clean || exit /b 1 & popd
pushd Dev && call Clean || exit /b 1 & popd
pushd VGM && call Clean || exit /b 1 & popd
pushd cpuspd && call Clean || exit /b 1 & popd
pushd Survey && call Clean || exit /b 1 & popd
