@echo off
setlocal

echo :
echo : Cleaning...
echo :
call Clean.cmd

echo :
echo : Creating System Images
echo :
copy /b ..\bl\bl.bin + ..\cpm22\os2ccp.bin + ..\cpm22\os3bdos.bin + ..\cbios\cbios_wbw.bin cpm_wbw.sys
copy /b ..\bl\bl.bin + ..\cpm22\os2ccp.bin + ..\cpm22\os3bdos.bin + ..\cbios\cbios_una.bin cpm_una.sys
copy /b ..\bl\bl.bin + ..\zcpr-dj\zcpr.bin + ..\zsdos\zsdos.bin + ..\cbios\cbios_wbw.bin zsys_wbw.sys
copy /b ..\bl\bl.bin + ..\zcpr-dj\zcpr.bin + ..\zsdos\zsdos.bin + ..\cbios\cbios_una.bin zsys_una.sys

echo :
echo : Building Floppy Disk Images...
echo :
call BuildFD.cmd cpm22 cpm_wbw
call BuildFD.cmd zsdos zsys_wbw
call BuildFD.cmd nzcom zsys_wbw
call BuildFD.cmd cpm3
call BuildFD.cmd zpm3
call BuildFD.cmd ws4

echo :
echo : Building Hard Disk Images...
echo :
call BuildHD.cmd cpm22 cpm_wbw
call BuildHD.cmd zsdos zsys_wbw
call BuildHD.cmd nzcom zsys_wbw
call BuildHD.cmd cpm3
call BuildHD.cmd zpm3
call BuildHD.cmd ws4
