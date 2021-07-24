@echo off
setlocal

if not exist ..\..\Binary\RCZ280_nat_zzr.rom goto :eof

rem ..\..\Tools\srecord\srec_cat.exe ..\..\Binary\RCZ280_nat_zzr.rom -Binary -Exclude 0x5000 0x7000 zzr_romldr.hex -Intel -Output ..\..\Binary\RCZ280_nat_zzr.hex -Intel || exit /b

..\..\Tools\srecord\srec_cat.exe ..\..\Binary\RCZ280_nat_zzr.rom -Binary -Output ..\..\Binary\RCZ280_nat_zzr.hex -Intel || exit /b

rem ..\..\Tools\srecord\srec_cat.exe ..\..\Binary\RCZ280_nat_zzr.hex -Intel -Output ..\..\Binary\RCZ280_nat_zzr_ldr.rom -Binary || exit /b

rem copy /b zzr_cfldr.bin + zzr_ptbl.bin + zzr_fill_1.bin + zzr_mon.bin + zzr_fill_2.bin + ..\..\Binary\RCZ280_nat_zzr_ldr.rom + zzr_fill_3.bin ..\..\Binary\hd1024_zzr_prefix.dat || exit /b

copy /b zzr_cfldr.bin + zzr_ptbl.bin + zzr_fill_1.bin + zzr_mon.bin + zzr_fill_2.bin + ..\..\Binary\RCZ280_nat_zzr.rom + zzr_fill_3.bin ..\..\Binary\hd1024_zzr_prefix.dat || exit /b

copy /b ..\..\Binary\hd1024_zzr_prefix.dat + ..\..\Binary\hd1024_cpm22.img + ..\..\Binary\hd1024_zsdos.img + ..\..\Binary\hd1024_nzcom.img + ..\..\Binary\hd1024_cpm3.img + ..\..\Binary\hd1024_zpm3.img + ..\..\Binary\hd1024_ws4.img ..\..\Binary\hd1024_zzr_combo.img || exit /b