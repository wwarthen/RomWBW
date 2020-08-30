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
echo Building Hard Disk Images (512 directory entry format)...
echo.
call BuildDisk.cmd cpm22 wbw_hd512 ..\cpm22\cpm_wbw.sys
call BuildDisk.cmd zsdos wbw_hd512 ..\zsdos\zsys_wbw.sys
call BuildDisk.cmd nzcom wbw_hd512 ..\zsdos\zsys_wbw.sys
call BuildDisk.cmd cpm3 wbw_hd512 ..\cpm3\cpmldr.sys
call BuildDisk.cmd zpm3 wbw_hd512 ..\cpm3\cpmldr.sys
call BuildDisk.cmd ws4 wbw_hd512

if exist ..\BPBIOS\bpbio-ww.rel call BuildDisk.cmd bp wbw_hd512

echo.
echo Building Combo Disk (512 directory entry format) Image...
copy /b ..\..\Binary\hd512_cpm22.img + ..\..\Binary\hd512_zsdos.img + ..\..\Binary\hd512_nzcom.img + ..\..\Binary\hd512_cpm3.img + ..\..\Binary\hd512_zpm3.img + ..\..\Binary\hd512_ws4.img ..\..\Binary\hd512_combo.img

echo.
echo Building Hard Disk Images (1024 directory entry format)...
echo.
call BuildDisk.cmd cpm22 wbw_hd1024 ..\cpm22\cpm_wbw.sys
call BuildDisk.cmd zsdos wbw_hd1024 ..\zsdos\zsys_wbw.sys
call BuildDisk.cmd nzcom wbw_hd1024 ..\zsdos\zsys_wbw.sys
call BuildDisk.cmd cpm3 wbw_hd1024 ..\cpm3\cpmldr.sys
call BuildDisk.cmd zpm3 wbw_hd1024 ..\cpm3\cpmldr.sys
call BuildDisk.cmd ws4 wbw_hd1024

if exist ..\BPBIOS\bpbio-ww.rel call BuildDisk.cmd bp wbw_hd1024

copy hd1024_prefix.dat ..\..\Binary\

echo.
echo Building Combo Disk (1024 directory entry format) Image...
copy /b hd1024_prefix.dat + ..\..\Binary\hd1024_cpm22.img + ..\..\Binary\hd1024_zsdos.img + ..\..\Binary\hd1024_nzcom.img + ..\..\Binary\hd1024_cpm3.img + ..\..\Binary\hd1024_zpm3.img + ..\..\Binary\hd1024_ws4.img ..\..\Binary\hd1024_combo.img
