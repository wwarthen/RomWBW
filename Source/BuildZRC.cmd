@echo off
setlocal

setlocal & cd ZRC && call Build || exit /b 1 & endlocal
