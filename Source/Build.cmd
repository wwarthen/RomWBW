@echo off
setlocal

:: call BuildDoc || exit /b
call BuildProp || exit /b
call BuildShared || exit /b
:: call BuildBP || exit /b
call BuildImages || exit /b
call BuildROM %* || exit /b
call BuildZRC || exit /b
call BuildZZRC || exit /b

if "%1" == "dist" (
  call Clean || exit /b
)