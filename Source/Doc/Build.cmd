@echo off
setlocal

setlocal & pushd "CPM 22 Manual" && call Build.cmd & endlocal
setlocal & pushd "ZCPR Manual" && call Build.cmd & endlocal
setlocal & pushd "RomWBW User Guide" && call Build.cmd & endlocal
setlocal & pushd "RomWBW System Guide" && call Build.cmd & endlocal