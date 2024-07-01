@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\srecord;%PATH%

if exist ..\..\Binary\FZ80_std.rom call :build_fz80

goto :eof

:build_fz80

srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x1B8 0x200 fz80_ptbl.bin -binary -offset 0x1B8 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x80000 0xE0000 ..\..\Binary\FZ80_std.rom -binary -offset 0x80000 -o temp.dat -binary
move temp.dat ..\..\Binary\hd1k_fz80_prefix.dat

copy /b ..\..\Binary\hd1k_fz80_prefix.dat + ..\..\Binary\hd1k_cpm22.img + ..\..\Binary\hd1k_zsdos.img + ..\..\Binary\hd1k_nzcom.img + ..\..\Binary\hd1k_cpm3.img + ..\..\Binary\hd1k_zpm3.img + ..\..\Binary\hd1k_ws4.img ..\..\Binary\hd1k_fz80_combo.img || exit /b

goto :eof
