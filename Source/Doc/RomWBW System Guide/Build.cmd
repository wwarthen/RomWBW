@echo off
setlocal

rem set MIKTEX_HOME=D:\miktex-portable\texmfs\install

rem if "%MIKTEX_HOME%"=="" goto :eof

rem set TEXSYSTEM=miktex
rem set MIKTEX_BINDIR=%MIKTEX_HOME%\miktex\bin
rem set MIKTEX_COMMONSTARTUPFILE=%MIKTEX_HOME%\miktex\config\miktexstartup.ini
rem set MIKTEX_GS_LIB=%MIKTEX_HOME%\ghostscript\base;%MIKTEX_HOME%\fonts
rem set MIKTEX_USERSTARTUPFILE=%MIKTEX_HOME%\miktex\config\miktexstartup.ini
rem set PATH=%MIKTEX_HOME%\miktex\bin;%PATH%

call texify -p --clean Main.ltx

if errorlevel 1 goto :eof

move /Y Main.pdf "..\..\..\Doc\RomWBW System Guide.pdf"