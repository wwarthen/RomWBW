@echo off
setlocal

if not exist ..\..\Binary\RCZ80_zrc.rom goto :eof

copy /b zrc_cfldr.bin + zrc_ptbl.bin + zrc_fill_1.bin + zrc_mon.bin + zrc_fill_2.bin + ..\..\Binary\RCZ80_zrc.rom + zrc_fill_3.bin ..\..\Binary\hd1024_zrc_prefix.dat || exit /b

copy /b ..\..\Binary\hd1024_zrc_prefix.dat + ..\..\Binary\hd1024_cpm22.img + ..\..\Binary\hd1024_zsdos.img + ..\..\Binary\hd1024_nzcom.img + ..\..\Binary\hd1024_cpm3.img + ..\..\Binary\hd1024_zpm3.img + ..\..\Binary\hd1024_ws4.img ..\..\Binary\hd1024_zrc_combo.img || exit /b