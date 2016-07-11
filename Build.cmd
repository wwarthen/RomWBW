@echo off
setlocal

if not exist Output md Output

pushd Source && call Build %* && popd
