@echo off
setlocal

if exist *.bin del *.bin
if exist *.com del *.com
if exist *.lst del *.lst
if exist *.hex del *.hex
if exist *.prn del *.prn

pushd DMAmon && call Clean || exit /b 1 & popd
pushd tstdskng && call Clean || exit /b 1 & popd
pushd inttest && call Clean || exit /b 1 & popd
pushd ppidetst && call Clean || exit /b 1 & popd
pushd ramtest && call Clean || exit /b 1 & popd
pushd I2C && call Clean || exit /b 1 & popd
pushd rzsz && call Clean || exit /b 1 & popd
pushd vdctest && call Clean || exit /b 1 & popd
pushd kbdtest && call Clean || exit /b 1 & popd
pushd ps2info && call Clean || exit /b 1 & popd
pushd 2piotst && call Clean || exit /b 1 & popd
pushd piomon && call Clean || exit /b 1 & popd
pushd banktest && call Clean || exit /b 1 & popd
pushd portswp && call Clean || exit /b 1 & popd
