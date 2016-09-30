@echo off
setlocal

setlocal & pushd Apps && call Build & endlocal
setlocal & pushd CPM22 && call Build & endlocal
setlocal & pushd ZCPR && call Build & endlocal
setlocal & pushd ZCPR-DJ && call Build & endlocal
setlocal & pushd ZSDOS && call Build & endlocal
setlocal & pushd CBIOS && call Build & endlocal
