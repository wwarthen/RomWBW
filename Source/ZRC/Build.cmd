@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\srecord;%PATH%

if exist ..\..\Binary\RCZ80_zrc.rom call :build_zrc

if exist ..\..\Binary\RCZ80_zrc_ram.rom call :build_zrc_ram

goto :eof

:build_zrc

srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x0 0x100 zrc_cfldr.bin -binary -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x100 0x200 zrc_ptbl.bin -binary -offset 0x100 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x1F000 0x20000 zrc_mon.bin -binary -offset 0x1F000 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x24000 0xA4000 ..\..\Binary\RCZ80_zrc.rom -binary -offset 0x24000 -o temp.dat -binary
move temp.dat ..\..\Binary\hd1k_zrc_prefix.dat

copy /b ..\..\Binary\hd1k_zrc_prefix.dat + ..\..\Binary\hd1k_cpm22.img + ..\..\Binary\hd1k_zsdos.img + ..\..\Binary\hd1k_nzcom.img + ..\..\Binary\hd1k_cpm3.img + ..\..\Binary\hd1k_zpm3.img + ..\..\Binary\hd1k_ws4.img ..\..\Binary\hd1k_zrc_combo.img || exit /b

goto :eof

:build_zrc_ram

srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x0 0x100 zrc_cfldr.bin -binary -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x100 0x200 zrc_ptbl.bin -binary -offset 0x100 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x1F000 0x20000 zrc_mon.bin -binary -offset 0x1F000 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x24000 0xA4000 ..\..\Binary\RCZ80_zrc_ram.rom -binary -offset 0x24000 -o temp.dat -binary
move temp.dat ..\..\Binary\hd1k_zrc_ram_prefix.dat

copy /b ..\..\Binary\hd1k_zrc_ram_prefix.dat + ..\..\Binary\hd1k_cpm22.img + ..\..\Binary\hd1k_zsdos.img + ..\..\Binary\hd1k_nzcom.img + ..\..\Binary\hd1k_cpm3.img + ..\..\Binary\hd1k_zpm3.img + ..\..\Binary\hd1k_ws4.img ..\..\Binary\hd1k_zrc_ram_combo.img || exit /b

goto :eof
