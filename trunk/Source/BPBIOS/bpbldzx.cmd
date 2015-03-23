@echo off

rem Wrapper to run bpbuild under the zx emulator.
rem This cmd file works around an issue
rem bpbuild has when the input filename on the
rem command line is the same as the output filename.
rem Bpbuild is trying to rename the existing output file to
rem a .bak, but fails because the input file is open.
rem So, if an input filename is specified, we take
rem steps to work around this.

setlocal

set PATH=%PATH%;..\..\Tools\zx;..\..\Tools\cpmtools;

set ZXBINDIR=../../tools/cpm/bin/
set ZXLIBDIR=../../tools/cpm/lib/
set ZXINCDIR=../../tools/cpm/include/

if .%1.==.. goto :skip

if exist bpimg.$$$ del bpimg.$$$
copy %1 bpimg.$$$
zx bpbuild -bpimg.$$$
del bpimg.$$$
goto :eof

:skip
zx bpbuild