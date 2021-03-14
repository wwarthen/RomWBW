@echo off
setlocal

setlocal & cd ZZR && call Build || exit /b 1 & endlocal
