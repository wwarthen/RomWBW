@echo off
setlocal

if exist *.bin del *.bin
if exist *.com del *.com
if exist *.lst del *.lst
if exist *.hex del *.hex
if exist *.prn del *.prn

pushd DMAmon && call Clean || exit /b 1 & popd
pushd dskyng && call Clean || exit /b 1 & popd
pushd inttst && call Clean || exit /b 1 & popd
pushd ppidetst && call Clean || exit /b 1 & popd
pushd ramtest && call Clean || exit /b 1 & popd
