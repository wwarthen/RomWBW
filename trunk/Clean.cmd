@echo off
setlocal

pushd Source && call Clean && popd

if exist *.img del *.img /Q
if exist debug.log del debug.log

if exist Output\*.* del Output\*.* /Q
