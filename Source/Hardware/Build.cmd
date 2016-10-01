@echo off
setlocal

setlocal & pushd Prop && call Build & endlocal
setlocal & pushd VDU && call Build & endlocal