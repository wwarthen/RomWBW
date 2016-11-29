@echo off
setlocal

setlocal & call BuildDoc || exit /b 1 & endlocal
setlocal & call BuildHardware || exit /b 1 & endlocal
setlocal & call BuildImages || exit /b 1 & endlocal
setlocal & call BuildShared || exit /b 1 & endlocal
setlocal & call BuildBP || exit /b 1 & endlocal
setlocal & call BuildROM %* || exit /b 1 & endlocal