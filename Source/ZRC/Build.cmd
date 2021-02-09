@echo off
setlocal

if not exist ..\..\Binary\RCZ80_zrc.rom goto :err

copy /b zrc_cfldr.bin + zrc_ptbl.bin + zrc_fill_1.bin + zrc_mon.bin + zrc_fill_2.bin + ..\..\Binary\RCZ80_zrc.rom + zrc_fill_3.bin ..\..\Binary\hd1024_zrc_prefix.dat

goto :eof

:err

echo *** Can't build ZRC prefix file -- missing "..\..\Binary\RCZ80_zrc.rom"
exit /b 1