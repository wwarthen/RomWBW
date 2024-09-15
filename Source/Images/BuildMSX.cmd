@echo off
setlocal

echo.
echo Building MSX Hard Disk Combo Image (1024 directory entry format)...
echo.

copy hd1k_prefix.dat ..\..\Binary\ || exit /b

copy /b hd1k_prefix.dat + ..\..\Binary\hd1k_cpm22.img + ..\..\Binary\hd1k_zsdos.img + ..\..\Binary\hd1k_cpm3.img + ..\..\Binary\hd1k_msxroms1.img + ..\..\Binary\hd1k_msxroms2.img ..\..\Binary\hd1k_msxcombo.img || exit /b
