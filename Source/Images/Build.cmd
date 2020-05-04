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
call BuildHD.cmd cpm22 wbw_hd0 ..\cpm22\cpm_wbw.sys
call BuildHD.cmd zsdos wbw_hd0 ..\zsdos\zsys_wbw.sys
call BuildHD.cmd nzcom wbw_hd0 ..\zsdos\zsys_wbw.sys
call BuildHD.cmd cpm3 wbw_hd0 ..\cpm3\cpmldr.sys
call BuildHD.cmd zpm3 wbw_hd0 ..\cpm3\cpmldr.sys
call BuildHD.cmd ws4 wbw_hd0

if exist ..\BPBIOS\bpbio-ww.rel call BuildHD.cmd bp wbw_hd

echo.
echo Building Combo Disk Image...
copy /b ..\..\Binary\hd_cpm22.img + ..\..\Binary\hd_zsdos.img + ..\..\Binary\hd_nzcom.img + ..\..\Binary\hd_cpm3.img + ..\..\Binary\hd_zpm3.img + ..\..\Binary\hd_ws4.img ..\..\Binary\hd_combo.img
