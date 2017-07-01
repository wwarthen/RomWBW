@echo off
setlocal

rem Wrapper to run bpbuild under the zx emulator.
rem This cmd file works around an issue
rem bpbuild has when the input filename on the
rem command line is the same as the output filename.
rem Bpbuild is trying to rename the existing output file to
rem a .bak, but fails because the input file is open.
rem So, if an input filename is specified, we take
rem steps to work around this.

set PATH=%PATH%;..\..\Tools\zx;..\..\Tools\cpmtools

set ZXBINDIR=../../tools/cpm/bin/
set ZXLIBDIR=../../tools/cpm/lib/
set ZXINCDIR=../../tools/cpm/include/

if .%1.==.. goto :skip
if not exist %1 goto :err

if exist bpsys.tmp del bpsys.tmp
copy %1 bpsys.tmp
zx bpbuild -bpsys.tmp
del bpsys.tmp
goto :eof

:skip
zx bpbuild
goto :eof

:err
echo.
echo Specified file %1 does not exist!
goto :eof