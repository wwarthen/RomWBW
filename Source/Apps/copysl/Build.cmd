@echo off
setlocal

:: copysl.com is currently distributed as a binary application, so
:: it is not built here.

copy /Y copysl.com ..\..\..\Binary\Apps\ || exit /b
copy /Y copysl.doc ..\..\..\Binary\Apps\ || exit /b
