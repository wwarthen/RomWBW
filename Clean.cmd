@echo off

setlocal

pushd Source && call Clean && popd
pushd Images && call Clean && popd
pushd Hardware && call Clean && popd

if exist *.img del *.img /Q
if exist *.log del *.log /Q

if exist Output rd /s /q Output