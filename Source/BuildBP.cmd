@echo off
setlocal

setlocal & cd BPBIOS && call Build || exit /b 1 & endlocal