@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\srecord;%PATH%

for %%f in (..\..\Binary\SZ80_*.rom) do call :build %%~nf

goto :eof

:build
echo.
echo Creating %1 disk image...
echo.

srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x1B8 0x200 sz80_ptbl.bin -binary -offset 0x1B8 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x80000 0xA0000 ..\..\Binary\%1.upd -binary -offset 0x80000 -o temp.dat -binary
move temp.dat ..\..\Binary\%1_hd1k_prefix.dat

copy /b ..\..\Binary\%1_hd1k_prefix.dat + ..\..\Binary\hd1k_cpm22.img + ..\..\Binary\hd1k_zsdos.img + ..\..\Binary\hd1k_nzcom.img + ..\..\Binary\hd1k_cpm3.img + ..\..\Binary\hd1k_zpm3.img + ..\..\Binary\hd1k_wp.img ..\..\Binary\%1_hd1k_combo.img || exit /b

goto :eof
