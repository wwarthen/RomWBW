@echo off
setlocal

if not exist Output md Output

pushd Images && Build && popd