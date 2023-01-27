@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%PATH%

set TASMTABS=%TOOLS%\tasm32

echo.
echo Building p-System BIOS Tester Loader for RomWBW...
echo.
tasm -t80 -g3 -dTESTBIOS loader.asm testldr.bin testldr.lst || exit /b
if errorlevel 1 goto :eof

echo.
echo Building p-System BIOS for RomWBW...
echo.
tasm -t80 -g3 bios.asm bios.bin bios.lst || exit /b
if errorlevel 1 goto :eof

echo.
echo Building p-System Loader for RomWBW...
echo.
tasm -t80 -g3 loader.asm loader.bin loader.lst || exit /b
if errorlevel 1 goto :eof

echo.
echo Generating p-System BIOS Tester filler...
echo.
tasm -t80 -g3 fill.asm fill.bin fill.lst || exit /b
if errorlevel 1 goto :eof

echo.
echo Generating p-System Boot Track filler...
echo.
tasm -t80 -g3 -dTESTBIOS fill.asm testfill.bin testfill.lst || exit /b
if errorlevel 1 goto :eof

echo.
echo Creating p-System BIOS Tester boot image
echo.
copy /b ..\Images\hd1k_prefix.dat + testldr.bin + bios.bin + biostest.dat + testfill.bin psystest.img || exit /b

echo.
echo Generating p-System Boot Track...
echo.
copy /b loader.bin + bios.bin + boot.dat + fill.bin trk0.bin  || exit /b

echo.
echo Generating p-System Disk Image...
echo.
copy /b ..\Images\hd1k_prefix.dat + trk0.bin + psys.vol + trk0.bin + blank.vol psys.img || exit /b

copy psys.img ..\..\Binary  || exit /b