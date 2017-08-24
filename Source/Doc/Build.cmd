@echo off
setlocal

setlocal & cd "ZCPR Manual" && call Build.cmd || exit /b 1 & endlocal
rem setlocal & cd "RomWBW User Guide" && call Build.cmd || exit /b 1 & endlocal
rem setlocal & cd "RomWBW System Guide" && call Build.cmd || exit /b 1 & endlocal