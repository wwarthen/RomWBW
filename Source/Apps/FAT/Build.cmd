@echo off
setlocal

REM FAT.com is currently distributed as a binary application, so
REM it is not built here.

copy /Y fat.com ..\..\..\Binary\Apps\ || exit /b
