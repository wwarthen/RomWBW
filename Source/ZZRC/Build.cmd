:: @echo off
setlocal

set ROMFILE=..\..\Binary\RCZ280_zzrc.rom
set ROMSIZE=262144

set TOOLS=../../Tools

set PATH=%TOOLS%\srecord;%PATH%

if exist ..\..\Binary\RCZ280_zzrc.rom call :build_zzrc

if exist ..\..\Binary\RCZ280_zzrc_ram.rom call :build_zzrc_ram

goto :eof

:build_zzrc

srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x0 0x100 zzrc_cfldr.bin -binary -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x100 0x200 zzrc_ptbl.bin -binary -offset 0x100 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x1F000 0x20000 zzrc_mon.bin -binary -offset 0x1F000 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x24000 0xA4000 ..\..\Binary\RCZ280_zzrc.rom -binary -offset 0x24000 -o temp.dat -binary
move temp.dat ..\..\Binary\hd1k_zzrc_prefix.dat

copy /b ..\..\Binary\hd1k_zzrc_prefix.dat + ..\..\Binary\hd1k_cpm22.img + ..\..\Binary\hd1k_zsdos.img + ..\..\Binary\hd1k_nzcom.img + ..\..\Binary\hd1k_cpm3.img + ..\..\Binary\hd1k_zpm3.img + ..\..\Binary\hd1k_ws4.img ..\..\Binary\hd1k_zzrc_combo.img || exit /b

goto :eof

:build_zzrc_ram

srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x0 0x100 zzrc_cfldr.bin -binary -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x100 0x200 zzrc_ptbl.bin -binary -offset 0x100 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x1F000 0x20000 zzrc_mon.bin -binary -offset 0x1F000 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x24000 0xA4000 ..\..\Binary\RCZ280_zzrc_ram.rom -binary -offset 0x24000 -o temp.dat -binary
move temp.dat ..\..\Binary\hd1k_zzrc_ram_prefix.dat

copy /b ..\..\Binary\hd1k_zzrc_ram_prefix.dat + ..\..\Binary\hd1k_cpm22.img + ..\..\Binary\hd1k_zsdos.img + ..\..\Binary\hd1k_nzcom.img + ..\..\Binary\hd1k_cpm3.img + ..\..\Binary\hd1k_zpm3.img + ..\..\Binary\hd1k_ws4.img ..\..\Binary\hd1k_zzrc_ram_combo.img || exit /b

goto :eof
