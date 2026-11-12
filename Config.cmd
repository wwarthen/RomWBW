@echo off
setlocal

rem hbconfig, the menu-driven config editor, see Tools\hbconfig\ReadMe.txt.
rem
rem   Config [<platform> [<config>]]           open the menu
rem   Config -show [<platform> [<config>]]     settings that differ from cfg_MASTER
rem   Config -check [<platform> [<config>]]    check every ;@DEPENDS rule
rem   Config -install                          (re)install the private Python
rem
rem Runs with its own Python in Tools\python, never the system one. When
rem that is missing it offers to download it, see install-python.ps1.
rem Only starts the tool, which is written with Claude (AI).

set "HB=%~dp0Tools\hbconfig"
set "PYEXE=%~dp0Tools\python\python.exe"

if /i "%~1"=="-install" goto install
if exist "%PYEXE%" goto run

echo hbconfig needs its own Python and the windows-curses package, about
echo 15 MB, downloaded from python.org and pypi.org into Tools\python.
echo Nothing outside this RomWBW folder is changed.
set "ANSWER="
set /p "ANSWER=Download it now? [y/N] "
if /i not "%ANSWER%"=="y" exit /b 1

:install
powershell -NoProfile -ExecutionPolicy Bypass -File "%HB%\install-python.ps1"
if errorlevel 1 exit /b 1
if /i "%~1"=="-install" exit /b 0

:run
"%PYEXE%" "%HB%\hbconfig.py" %*
exit /b %errorlevel%
