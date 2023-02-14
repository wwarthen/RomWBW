:: @echo off
setlocal

set ROMFILE=..\..\Binary\RCZ280_zzrc.rom
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

rem ..\..\Tools\srecord\srec_cat.exe ..\..\Binary\RCZ280_zzrc.rom -Binary -Exclude 0x5000 0x7000 zzrc_romldr.hex -Intel -Output ..\..\Binary\RCZ280_zzrc.hex -Intel || exit /b

..\..\Tools\srecord\srec_cat.exe ..\..\Binary\RCZ280_zzrc.rom -Binary -Output ..\..\Binary\RCZ280_zzrc.hex -Intel || exit /b

rem ..\..\Tools\srecord\srec_cat.exe ..\..\Binary\RCZ280_zzrc.hex -Intel -Output ..\..\Binary\RCZ280_zzrc_ldr.rom -Binary || exit /b

rem copy /b zzrc_cfldr.bin + zzrc_ptbl.bin + zzrc_fill_1.bin + zzrc_mon.bin + zzrc_fill_2.bin + ..\..\Binary\RCZ280_zzrc_ldr.rom + zzrc_fill_3.bin ..\..\Binary\hd1k_zzrc_prefix.dat || exit /b

copy /b zzrc_cfldr.bin + zzrc_ptbl.bin + zzrc_fill_1.bin + zzrc_mon.bin + zzrc_fill_2.bin + ..\..\Binary\RCZ280_zzrc.rom + zzrc_fill_3.bin ..\..\Binary\hd1k_zzrc_prefix.dat || exit /b

copy /b ..\..\Binary\hd1k_zzrc_prefix.dat + ..\..\Binary\hd1k_cpm22.img + ..\..\Binary\hd1k_zsdos.img + ..\..\Binary\hd1k_nzcom.img + ..\..\Binary\hd1k_cpm3.img + ..\..\Binary\hd1k_zpm3.img + ..\..\Binary\hd1k_ws4.img ..\..\Binary\hd1k_zzrc_combo.img || exit /b

goto :eof

:filesize
set FILESIZE=%~z1
goto :eof