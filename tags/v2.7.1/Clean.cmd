@echo off

setlocal

pushd Source && call Clean && popd
pushd Images && call Clean && popd

if exist *.img del *.img /Q
if exist *.log del *.log /Q

if exist Output\*.* del Output\*.* /Q
