@echo off
setlocal

echo :
echo : Cleaning...
echo :
call Clean.cmd

echo :
echo : Building Floppy Disk Images...
echo :
call BuildFD.cmd cpm22 ..\cpm22\cpm_wbw
call BuildFD.cmd zsdos ..\zsdos\zsys_wbw
call BuildFD.cmd nzcom ..\zsdos\zsys_wbw
call BuildFD.cmd cpm3
call BuildFD.cmd zpm3
call BuildFD.cmd ws4

echo :
echo : Building Hard Disk Images...
echo :
call BuildHD.cmd cpm22 ..\cpm22\cpm_wbw
call BuildHD.cmd zsdos ..\zsdos\zsys_wbw
call BuildHD.cmd nzcom ..\zsdos\zsys_wbw
call BuildHD.cmd cpm3
call BuildHD.cmd zpm3
call BuildHD.cmd ws4
call BuildHD.cmd bp
