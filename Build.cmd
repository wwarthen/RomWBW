@echo off
setlocal

setlocal & pushd Source && call Build %* & endlocal
