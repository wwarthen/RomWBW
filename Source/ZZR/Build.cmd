@echo off
setlocal

set ROMFILE=..\..\Binary\RCZ280_nat_zzr.rom
set ROMSIZE=262144

if not exist %ROMFILE% goto :eof

::
:: The ROM image *must* be exactly 256K or the resulting disk
:: image produced below will be invalid.  Check for the proper size.
::

call :filesize %ROMFILE%

if "%FILESIZE%" neq "%ROMSIZE%" (
  echo.
  echo.
  echo ERROR: "%ROMFILE%" is not exactly %ROMSIZE% bytes as required!!!
  echo You must specify a ROMSIZE of "256" when building the ZZRCC ROM image.
  echo.
  echo.
  exit /b 1
)

rem ..\..\Tools\srecord\srec_cat.exe ..\..\Binary\RCZ280_nat_zzr.rom -Binary -Exclude 0x5000 0x7000 zzr_romldr.hex -Intel -Output ..\..\Binary\RCZ280_nat_zzr.hex -Intel || exit /b

..\..\Tools\srecord\srec_cat.exe ..\..\Binary\RCZ280_nat_zzr.rom -Binary -Output ..\..\Binary\RCZ280_nat_zzr.hex -Intel || exit /b

rem ..\..\Tools\srecord\srec_cat.exe ..\..\Binary\RCZ280_nat_zzr.hex -Intel -Output ..\..\Binary\RCZ280_nat_zzr_ldr.rom -Binary || exit /b

rem copy /b zzr_cfldr.bin + zzr_ptbl.bin + zzr_fill_1.bin + zzr_mon.bin + zzr_fill_2.bin + ..\..\Binary\RCZ280_nat_zzr_ldr.rom + zzr_fill_3.bin ..\..\Binary\hd1k_zzr_prefix.dat || exit /b

copy /b zzr_cfldr.bin + zzr_ptbl.bin + zzr_fill_1.bin + zzr_mon.bin + zzr_fill_2.bin + ..\..\Binary\RCZ280_nat_zzr.rom + zzr_fill_3.bin ..\..\Binary\hd1k_zzr_prefix.dat || exit /b

copy /b ..\..\Binary\hd1k_zzr_prefix.dat + ..\..\Binary\hd1k_cpm22.img + ..\..\Binary\hd1k_zsdos.img + ..\..\Binary\hd1k_nzcom.img + ..\..\Binary\hd1k_cpm3.img + ..\..\Binary\hd1k_zpm3.img + ..\..\Binary\hd1k_ws4.img ..\..\Binary\hd1k_zzr_combo.img || exit /b

goto :eof

:filesize
set FILESIZE=%~z1
goto :eof