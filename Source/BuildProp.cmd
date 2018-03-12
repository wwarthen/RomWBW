@echo off
setlocal

setlocal & cd Prop && call Build || exit /b 1 & endlocal
