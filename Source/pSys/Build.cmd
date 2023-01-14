@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%PATH%

set TASMTABS=%TOOLS%\tasm32

echo.
echo Building p-System Loader for RomWBW...
echo.
tasm -t80 -g3 loader.asm loader.bin loader.lst || exit /b
if errorlevel 1 goto :eof

echo.
echo Building p-System BIOS for RomWBW...
echo.
tasm -t80 -g3 bios.asm bios.bin bios.lst || exit /b
if errorlevel 1 goto :eof

::echo.
::echo Creating p-System BIOS Tester boot image
::echo.
::copy /b loader.bin + bios.bin + biostest.dat psys.bin

echo.
echo Generating p-System Boot Track...
echo.
copy /b loader.bin + bios.bin + boot.dat + fill.dat trk0.bin  || exit /b

echo.
echo Generating p-System Disk Image...
echo.
copy /b trk0.bin + psys.vol + trk0.bin + blank.vol psys.img || exit /b

copy psys.img ..\..\Binary  || exit /b