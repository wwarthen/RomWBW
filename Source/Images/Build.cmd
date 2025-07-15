@echo off
setlocal

:: call BuildDisk.cmd bp hd wbw_hd1k ..\zsdos\zsys_wbw.sys
:: copy /b hd1k_prefix.dat + ..\..\Binary\hd1k_bp.img + ..\..\Binary\hd1k_cpm22.img + ..\..\Binary\hd1k_zsdos.img + ..\..\Binary\hd1k_nzcom.img + ..\..\Binary\hd1k_cpm3.img + ..\..\Binary\hd1k_zpm3.img + ..\..\Binary\hd1k_ws4.img ..\..\Binary\hd1k_combo_bp.img || exit /b
:: goto :eof

echo.
echo Building Floppy Disk Images...
echo.
call BuildDisk.cmd cpm22 fd wbw_fd144 ..\cpm22\cpm_wbw.sys || exit /b
call BuildDisk.cmd zsdos fd wbw_fd144 ..\zsdos\zsys_wbw.sys || exit /b
call BuildDisk.cmd nzcom fd wbw_fd144 ..\zsdos\zsys_wbw.sys || exit /b
call BuildDisk.cmd cpm3 fd wbw_fd144 ..\cpm3\cpmldr.sys || exit /b
call BuildDisk.cmd zpm3 fd wbw_fd144 ..\zpm3\zpmldr.sys || exit /b
call BuildDisk.cmd z3plus fd wbw_fd144 ..\cpm3\cpmldr.sys || exit /b
call BuildDisk.cmd ws4 fd wbw_fd144 || exit /b
call BuildDisk.cmd qpm fd wbw_fd144 ..\qpm\qpm_wbw.sys || exit /b
call BuildDisk.cmd z80asm fd wbw_fd144 || exit /b
call BuildDisk.cmd aztecc fd wbw_fd144 || exit /b
call BuildDisk.cmd hitechc fd wbw_fd144 || exit /b
call BuildDisk.cmd tpascal fd wbw_fd144 || exit /b
call BuildDisk.cmd bascomp fd wbw_fd144 || exit /b
call BuildDisk.cmd cobol fd wbw_fd144 || exit /b
call BuildDisk.cmd fortran fd wbw_fd144 || exit /b
call BuildDisk.cmd games fd wbw_fd144 || exit /b
call BuildDisk.cmd cowgol fd wbw_fd144 || exit /b

echo.
echo Building Hard Disk Images (512 directory entry format)...
echo.
call BuildDisk.cmd blank hd wbw_hd512 || exit /b
call BuildDisk.cmd cpm22 hd wbw_hd512 ..\cpm22\cpm_wbw.sys || exit /b
call BuildDisk.cmd zsdos hd wbw_hd512 ..\zsdos\zsys_wbw.sys || exit /b
call BuildDisk.cmd nzcom hd wbw_hd512 ..\zsdos\zsys_wbw.sys || exit /b
call BuildDisk.cmd cpm3 hd wbw_hd512 ..\cpm3\cpmldr.sys || exit /b
call BuildDisk.cmd zpm3 hd wbw_hd512 ..\zpm3\zpmldr.sys || exit /b
call BuildDisk.cmd z3plus hd wbw_hd512 ..\cpm3\cpmldr.sys || exit /b
call BuildDisk.cmd ws4 hd wbw_hd512 || exit /b
call BuildDisk.cmd dos65 hd wbw_hd512 ..\zsdos\zsys_wbw.sys || exit /b
call BuildDisk.cmd qpm hd wbw_hd512 ..\qpm\qpm_wbw.sys || exit /b
call BuildDisk.cmd z80asm hd wbw_hd512 || exit /b
call BuildDisk.cmd aztecc hd wbw_hd512 || exit /b
call BuildDisk.cmd hitechc hd wbw_hd512 || exit /b
call BuildDisk.cmd tpascal hd wbw_hd512 || exit /b
call BuildDisk.cmd bascomp hd wbw_hd512 || exit /b
call BuildDisk.cmd cobol hd wbw_hd512 || exit /b
call BuildDisk.cmd fortran hd wbw_hd512 || exit /b
call BuildDisk.cmd games hd wbw_hd512 || exit /b
call BuildDisk.cmd cowgol hd wbw_hd512 || exit /b
call BuildDisk.cmd msxroms1 hd wbw_hd512 || exit /b
call BuildDisk.cmd msxroms2 hd wbw_hd512 || exit /b
call BuildDisk.cmd infocom hd wbw_hd512 || exit /b

:: echo.
:: echo Building Combo Disk (512 directory entry format) Image...
:: copy /b ..\..\Binary\hd512_cpm22.img + ..\..\Binary\hd512_zsdos.img + ..\..\Binary\hd512_nzcom.img + ..\..\Binary\hd512_cpm3.img + ..\..\Binary\hd512_zpm3.img + ..\..\Binary\hd512_ws4.img ..\..\Binary\hd512_combo.img || exit /b

echo.
echo Building Hard Disk Images (1024 directory entry format)...
echo.
call BuildDisk.cmd blank hd wbw_hd1k || exit /b
call BuildDisk.cmd cpm22 hd wbw_hd1k ..\cpm22\cpm_wbw.sys || exit /b
call BuildDisk.cmd zsdos hd wbw_hd1k ..\zsdos\zsys_wbw.sys || exit /b
call BuildDisk.cmd nzcom hd wbw_hd1k ..\zsdos\zsys_wbw.sys || exit /b
call BuildDisk.cmd cpm3 hd wbw_hd1k ..\cpm3\cpmldr.sys || exit /b
call BuildDisk.cmd zpm3 hd wbw_hd1k ..\zpm3\zpmldr.sys || exit /b
call BuildDisk.cmd z3plus hd wbw_hd1k ..\cpm3\cpmldr.sys || exit /b
call BuildDisk.cmd ws4 hd wbw_hd1k || exit /b
call BuildDisk.cmd qpm hd wbw_hd1k ..\qpm\qpm_wbw.sys || exit /b
call BuildDisk.cmd z80asm hd wbw_hd1k || exit /b
call BuildDisk.cmd aztecc hd wbw_hd1k || exit /b
call BuildDisk.cmd hitechc hd wbw_hd1k || exit /b
call BuildDisk.cmd tpascal hd wbw_hd1k || exit /b
call BuildDisk.cmd bascomp hd wbw_hd1k || exit /b
call BuildDisk.cmd cobol hd wbw_hd1k || exit /b
call BuildDisk.cmd fortran hd wbw_hd1k || exit /b
call BuildDisk.cmd games hd wbw_hd1k || exit /b
call BuildDisk.cmd cowgol hd wbw_hd1k || exit /b
call BuildDisk.cmd msxroms1 hd wbw_hd1k || exit /b
call BuildDisk.cmd msxroms2 hd wbw_hd1k || exit /b
call BuildDisk.cmd infocom hd wbw_hd1k || exit /b

if exist ..\BPBIOS\bp*.rel call BuildDisk.cmd bp hd wbw_hd1k ..\zsdos\zsys_wbw.sys || exit /b

copy hd1k_prefix.dat ..\..\Binary\ || exit /b

:: echo.
:: echo Building Combo Disk (1024 directory entry format) Image...
:: copy /b hd1k_prefix.dat + ..\..\Binary\hd1k_cpm22.img + ..\..\Binary\hd1k_zsdos.img + ..\..\Binary\hd1k_nzcom.img + ..\..\Binary\hd1k_cpm3.img + ..\..\Binary\hd1k_zpm3.img + ..\..\Binary\hd1k_ws4.img ..\..\Binary\hd1k_combo.img || exit /b

call BuildImg.cmd || exit /b
