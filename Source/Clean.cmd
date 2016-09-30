@echo off
setlocal

setlocal & pushd Apps && call Clean.cmd & endlocal
setlocal & pushd CPM22 && call Clean.cmd & endlocal
setlocal & pushd ZCPR && call Clean.cmd & endlocal
setlocal & pushd ZCPR-DJ && call Clean.cmd & endlocal
setlocal & pushd ZSDOS && call Clean.cmd & endlocal
setlocal & pushd CBIOS && call Clean.cmd & endlocal

setlocal & pushd BPBIOS && call Clean.cmd & endlocal

setlocal & pushd HBIOS && call Clean.cmd & endlocal

setlocal & pushd Doc && call Clean.cmd & endlocal