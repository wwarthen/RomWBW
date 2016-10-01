@echo off
setlocal

setlocal & cd Doc && call Build || exit /b 1 & endlocal