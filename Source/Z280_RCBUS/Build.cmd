@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\srecord;%PATH%

for %%f in (..\..\Binary\RCZ280_rcbus_*.rom) do call :build %%~nf

goto :eof

:build
echo.
echo Creating %1 disk image...
echo.

srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x1B8 0x200 ptbl.bin -binary -offset 0x1B8 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x24000 0xA4000 ..\..\Binary\%1.rom -binary -offset 0x24000 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x240EF 0x24100 -generate 0x240EF 0x24100 -repeat-data 0xED 0xBF 0xED 0xB7 0xCB 0x7C 0x20 0xFA 0x2E 0x00 0x0E 0x08 0xED 0x6E 0xC3 0x00 0x00 -o temp.dat -binary
move temp.dat ..\..\Binary\%1_hd1k_prefix.dat

copy /b ..\..\Binary\%1_hd1k_prefix.dat + ..\..\Binary\hd1k_cpm22.img + ..\..\Binary\hd1k_zsdos.img + ..\..\Binary\hd1k_nzcom.img + ..\..\Binary\hd1k_cpm3.img + ..\..\Binary\hd1k_zpm3.img + ..\..\Binary\hd1k_wp.img ..\..\Binary\%1_hd1k_combo.img || exit /b

goto :eof
