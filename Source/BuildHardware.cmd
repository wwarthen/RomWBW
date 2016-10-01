@echo off
setlocal

setlocal & cd Hardware && call Build || exit /b 1 & endlocal
