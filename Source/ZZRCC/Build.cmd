:: @echo off
setlocal

set ROMFILE=..\..\Binary\RCZ280_zzrcc.rom
set ROMSIZE=262144

set TOOLS=../../Tools

set PATH=%TOOLS%\srecord;%PATH%

if exist ..\..\Binary\RCZ280_zzrcc.rom call :build_zzrcc

if exist ..\..\Binary\RCZ280_zzrcc_ram.rom call :build_zzrcc_ram

goto :eof

:build_zzrcc

srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x0 0x200 zzrcc_cfldr.bin -binary -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x1B8 0x200 zzrcc_ptbl.bin -binary -offset 0x1B8 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x1F000 0x20000 zzrcc_mon.bin -binary -offset 0x1F000 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x24000 0xA4000 ..\..\Binary\RCZ280_zzrcc.rom -binary -offset 0x24000 -o temp.dat -binary
move temp.dat ..\..\Binary\hd1k_zzrcc_prefix.dat

copy /b ..\..\Binary\hd1k_zzrcc_prefix.dat + ..\..\Binary\hd1k_cpm22.img + ..\..\Binary\hd1k_zsdos.img + ..\..\Binary\hd1k_nzcom.img + ..\..\Binary\hd1k_cpm3.img + ..\..\Binary\hd1k_zpm3.img + ..\..\Binary\hd1k_ws4.img ..\..\Binary\hd1k_zzrcc_combo.img || exit /b

goto :eof

:build_zzrcc_ram

srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x0 0x200 zzrcc_cfldr.bin -binary -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x1B8 0x200 zzrcc_ptbl.bin -binary -offset 0x1B8 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x1F000 0x20000 zzrcc_mon.bin -binary -offset 0x1F000 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x24000 0xA4000 ..\..\Binary\RCZ280_zzrcc_ram.rom -binary -offset 0x24000 -o temp.dat -binary
move temp.dat ..\..\Binary\hd1k_zzrcc_ram_prefix.dat

copy /b ..\..\Binary\hd1k_zzrcc_ram_prefix.dat + ..\..\Binary\hd1k_cpm22.img + ..\..\Binary\hd1k_zsdos.img + ..\..\Binary\hd1k_nzcom.img + ..\..\Binary\hd1k_cpm3.img + ..\..\Binary\hd1k_zpm3.img + ..\..\Binary\hd1k_ws4.img ..\..\Binary\hd1k_zzrcc_ram_combo.img || exit /b

goto :eof
