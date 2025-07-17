@echo off
setlocal

:: call BuildDoc || exit /b
call BuildProp || exit /b
call BuildShared || exit /b
call BuildImages || exit /b
call BuildROM %* || exit /b
call BuildZRC || exit /b
call BuildZ1RCC || exit /b
call BuildZZRCC || exit /b
call BuildZRC512 || exit /b
call BuildFZ80 || exit /b
call BuildEZ512 || exit /b

if "%1" == "dist" (
  call Clean || exit /b
)
