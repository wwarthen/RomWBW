@echo off
setlocal

call :clean syscopy || exit /b
call :clean assign || exit /b
call :clean format || exit /b
call :clean talk || exit /b
call :clean mode || exit /b
call :clean rtc || exit /b
call :clean timer || exit /b
call :clean sysgen || exit /b
call :clean XM || exit /b
call :clean FDU || exit /b
call :clean Tune || exit /b
call :clean FAT || exit /b
call :clean Test || exit /b
call :clean ZMP || exit /b
call :clean ZMD || exit /b
call :clean Dev || exit /b
call :clean VGM || exit /b
call :clean cpuspd || exit /b
call :clean reboot || exit /b
call :clean Survey || exit /b
call :clean HTalk || exit /b
call :clean BBCBASIC || exit /b
call :clean copysl || exit /b
call :clean slabel || exit /b
call :clean ZDE || exit /b

goto :eof

:clean
pushd %1 && call Clean || exit /b & popd
goto :eof
