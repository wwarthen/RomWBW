@echo off
setlocal

setlocal & cd Images && call Build || exit /b 1 & endlocal