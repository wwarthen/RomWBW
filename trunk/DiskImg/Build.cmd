@echo off

setlocal
set path=..\tools\cpmtools;%path%

echo Creating partition 0...
copy /b Blank.img hd0.tmp >nul
if exist hd0\*. cpmcp -f hd0 hd0.tmp hd0/* 0:

echo Creating partition 1...
copy /b Blank.img hd1.tmp >nul
if exist hd1\*. cpmcp -f hd0 hd1.tmp hd1/* 0:

echo Creating partition 2...
copy /b Blank.img hd2.tmp >nul
if exist hd2\*. cpmcp -f hd0 hd2.tmp hd2/* 0:

echo Creating partition 3...
copy /b Blank.img hd3.tmp >nul
if exist hd3\*. cpmcp -f hd0 hd3.tmp hd3/* 0:

echo Building final image...
copy /b hd*.tmp Disk.img

del *.tmp
