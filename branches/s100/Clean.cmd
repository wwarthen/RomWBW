@echo off
pushd Source
call Clean.cmd
popd
if exist Output\*.* del Output\*.* /Q