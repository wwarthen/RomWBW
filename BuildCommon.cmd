@echo off
setlocal

setlocal & pushd Source && call BuildCommon & endlocal
setlocal & pushd Hardware && call Build & endlocal