@echo off
setlocal

echo.
echo Building Floppy Disk Images...
echo.
call BuildDisk.cmd cpm22 wbw_fd144 ..\cpm22\cpm_wbw.sys
call BuildDisk.cmd zsdos wbw_fd144 ..\zsdos\zsys_wbw.sys
call BuildDisk.cmd nzcom wbw_fd144 ..\zsdos\zsys_wbw.sys
call BuildDisk.cmd cpm3 wbw_fd144 ..\cpm3\cpmldr.sys
call BuildDisk.cmd zpm3 wbw_fd144 ..\cpm3\cpmldr.sys
call BuildDisk.cmd ws4 wbw_fd144

echo.
echo Building Legacy Hard Disk Images...
echo.
call BuildDisk.cmd cpm22 wbw_hd ..\cpm22\cpm_wbw.sys
call BuildDisk.cmd zsdos wbw_hd ..\zsdos\zsys_wbw.sys
call BuildDisk.cmd nzcom wbw_hd ..\zsdos\zsys_wbw.sys
call BuildDisk.cmd cpm3 wbw_hd ..\cpm3\cpmldr.sys
call BuildDisk.cmd zpm3 wbw_hd ..\cpm3\cpmldr.sys
call BuildDisk.cmd ws4 wbw_hd

if exist ..\BPBIOS\bpbio-ww.rel call BuildDisk.cmd bp wbw_hd

echo.
echo Building Combo Disk (legacy format) Image...
copy /b ..\..\Binary\hd_cpm22.img + ..\..\Binary\hd_zsdos.img + ..\..\Binary\hd_nzcom.img + ..\..\Binary\hd_cpm3.img + ..\..\Binary\hd_zpm3.img + ..\..\Binary\hd_ws4.img ..\..\Binary\hd_combo.img

echo.
echo Building New Hard Disk Images...
echo.
call BuildDisk.cmd cpm22 wbw_hdnew ..\cpm22\cpm_wbw.sys
call BuildDisk.cmd zsdos wbw_hdnew ..\zsdos\zsys_wbw.sys
call BuildDisk.cmd nzcom wbw_hdnew ..\zsdos\zsys_wbw.sys
call BuildDisk.cmd cpm3 wbw_hdnew ..\cpm3\cpmldr.sys
call BuildDisk.cmd zpm3 wbw_hdnew ..\cpm3\cpmldr.sys
call BuildDisk.cmd ws4 wbw_hdnew

if exist ..\BPBIOS\bpbio-ww.rel call BuildDisk.cmd bp wbw_hdnew

copy hdnew_prefix.bin ..\..\Binary\

echo.
echo Building Combo Disk (new format) Image...
copy /b hdnew_prefix.bin + ..\..\Binary\hdnew_cpm22.img + ..\..\Binary\hdnew_zsdos.img + ..\..\Binary\hdnew_nzcom.img + ..\..\Binary\hdnew_cpm3.img + ..\..\Binary\hdnew_zpm3.img + ..\..\Binary\hdnew_ws4.img ..\..\Binary\hdnew_combo.img
