@echo off
setlocal

REM setlocal & call BuildDoc || exit /b 1 & endlocal
setlocal & call BuildProp || exit /b 1 & endlocal
setlocal & call BuildShared || exit /b 1 & endlocal
REM setlocal & call BuildBP || exit /b 1 & endlocal
setlocal & call BuildImages || exit /b 1 & endlocal
setlocal & call BuildROM %* || exit /b 1 & endlocal