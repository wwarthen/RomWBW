@echo off
setlocal

setlocal & cd "CPM 22 Manual" && call Build.cmd || exit /b 1 & endlocal
setlocal & cd "ZCPR Manual" && call Build.cmd || exit /b 1 & endlocal
setlocal & cd "RomWBW User Guide" && call Build.cmd || exit /b 1 & endlocal
setlocal & cd "RomWBW System Guide" && call Build.cmd || exit /b 1 & endlocal