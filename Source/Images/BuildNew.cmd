@echo off
setlocal

echo.
echo Building Floppy Disk Images...
echo.
call BuildFD.cmd cpm22 wbw_fd144 ..\cpm22\cpm_wbw.sys
call BuildFD.cmd zsdos wbw_fd144 ..\zsdos\zsys_wbw.sys
call BuildFD.cmd nzcom wbw_fd144 ..\zsdos\zsys_wbw.sys
call BuildFD.cmd cpm3 wbw_fd144 ..\cpm3\cpmldr.sys
call BuildFD.cmd zpm3 wbw_fd144 ..\cpm3\cpmldr.sys
call BuildFD.cmd ws4 wbw_fd144

echo.
echo Building Hard Disk Images...
echo.
call BuildHD.cmd cpm22 wbw_hd_new ..\cpm22\cpm_wbw.sys
call BuildHD.cmd zsdos wbw_hd_new ..\zsdos\zsys_wbw.sys
call BuildHD.cmd nzcom wbw_hd_new ..\zsdos\zsys_wbw.sys
call BuildHD.cmd cpm3 wbw_hd_new ..\cpm3\cpmldr.sys
call BuildHD.cmd zpm3 wbw_hd_new ..\cpm3\cpmldr.sys
call BuildHD.cmd ws4 wbw_hd_new

if exist ..\BPBIOS\bpbio-ww.rel call BuildHD.cmd bp wbw_hd_new

copy hd_prefix.dat ..\..\Binary\

echo.
echo Build Hard Disk Images...
copy /b hd_prefix.dat + ..\..\Binary\hd_cpm22.bin ..\..\Binary\hd_cpm22.img
copy /b hd_prefix.dat + ..\..\Binary\hd_zsdos.bin ..\..\Binary\hd_zsdos.img
copy /b hd_prefix.dat + ..\..\Binary\hd_nzcom.bin ..\..\Binary\hd_nzcom.img
copy /b hd_prefix.dat + ..\..\Binary\hd_cpm3.bin ..\..\Binary\hd_cpm3.img
copy /b hd_prefix.dat + ..\..\Binary\hd_zpm3.bin ..\..\Binary\hd_zpm3.img
copy /b hd_prefix.dat + ..\..\Binary\hd_ws4.bin ..\..\Binary\hd_ws4.img
if exist ..\..\Binary\hd_bp.bin copy /b hd_prefix.dat + ..\..\Binary\hd_bp.bin

echo.
echo Building Combo Disk Image...
copy /b hd_prefix.dat + ..\..\Binary\hd_cpm22.bin + ..\..\Binary\hd_zsdos.bin + ..\..\Binary\hd_nzcom.bin + ..\..\Binary\hd_cpm3.bin + ..\..\Binary\hd_zpm3.bin + ..\..\Binary\hd_ws4.bin ..\..\Binary\hd_combo.img
