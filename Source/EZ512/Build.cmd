@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\zxcc;%TOOLS%\srecord;%TOOLS%\compress;%PATH%

set CPMDIR80=%TOOLS%/cpm/

zxcc z80asm -decomp/HL

for %%f in (..\..\Binary\RCZ80_ez512_*.upd) do call :build %%~nf

goto :eof

:build
echo.
echo Creating %1 disk image...
echo.

srec_cat -generate 0x0 0x100000 --constant 0x00 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x0 0x200 ez512_cfldr.bin -binary -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x1B8 0x200 ez512_ptbl.bin -binary -offset 0x1B8 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x1F000 0x20000 ez512_mon.bin -binary -offset 0x1F000 -o temp.dat -binary
srec_cat temp.dat -binary -exclude 0x24000 0xA4000 ..\..\Binary\%1.rom -binary -offset 0x24000 -o temp.dat -binary
move temp.dat ..\..\Binary\%1_hd1k_prefix.dat

copy /b ..\..\Binary\%1_hd1k_prefix.dat + ..\..\Binary\hd1k_cpm22.img + ..\..\Binary\hd1k_zsdos.img + ..\..\Binary\hd1k_nzcom.img + ..\..\Binary\hd1k_cpm3.img + ..\..\Binary\hd1k_zpm3.img + ..\..\Binary\hd1k_wp.img ..\..\Binary\%1_hd1k_combo.img || exit /b

::
:: The following lines produce a 64K ROM that can be used in the EaZy80-512.
:: In order to fit in the required 64K, TastyBASIC and the Game components
:: are removed from the ROM.  If the layout of the ROM components
:: changes (see ..\Source\layout.inc), the address range that is carved
:: out below may need to be adjusted.
::
srec_cat ..\..\Binary\%1.upd -binary -exclude 0x13700 0x14A00 -fill 0xC9 0x13700 0x14A00 -o temp.upd -binary
compress temp.upd
srec_cat decomp.hex -intel temp.upd.cmp -binary -offset 3 -o ..\..\Binary\%1_64k.rom -binary

goto :eof
