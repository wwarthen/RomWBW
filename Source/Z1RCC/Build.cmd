@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\srecord;%PATH%

if exist ..\..\Binary\RCZ180_z1rcc.rom call :build_z1rcc

goto :eof

:build_z1rcc

srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x0 0x200 z1rcc_cfldr.bin -binary -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x1B8 0x200 z1rcc_ptbl.bin -binary -offset 0x1B8 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x1F000 0x20000 z1rcc_mon.bin -binary -offset 0x1F000 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x24000 0xA4000 ..\..\Binary\RCZ180_z1rcc.rom -binary -offset 0x24000 -o temp.dat -binary
move temp.dat ..\..\Binary\hd1k_z1rcc_prefix.dat

copy /b ..\..\Binary\hd1k_z1rcc_prefix.dat + ..\..\Binary\hd1k_cpm22.img + ..\..\Binary\hd1k_zsdos.img + ..\..\Binary\hd1k_nzcom.img + ..\..\Binary\hd1k_cpm3.img + ..\..\Binary\hd1k_zpm3.img + ..\..\Binary\hd1k_ws4.img ..\..\Binary\hd1k_z1rcc_combo.img || exit /b

goto :eof
