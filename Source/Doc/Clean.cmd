@echo off
setlocal

setlocal & pushd CPM 22 Manual && call Clean.cmd & endlocal
setlocal & pushd ZCPR Manual && call Clean.cmd & endlocal
setlocal & pushd RomWBW User Guide && call Clean.cmd & endlocal
setlocal & pushd RomWBW System Guide && call Clean.cmd & endlocal
