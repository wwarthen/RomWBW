@echo off
setlocal

REM call BuildDoc || exit /b
call BuildProp || exit /b
call BuildShared || exit /b
REM call BuildBP || exit /b
call BuildImages || exit /b
call BuildROM %* || exit /b
call BuildZRC || exit /b
call BuildZZR || exit /b

if "%1" == "dist" (
  call Clean || exit /b
)