@echo off
setlocal

echo :
echo : Cleaning...
echo :
call Clean.cmd

echo :
echo : Building Floppy Disk Images...
echo :
call BuildFD.cmd cpm22
call BuildFD.cmd zsdos
call BuildFD.cmd nzcom
call BuildFD.cmd cpm3
call BuildFD.cmd zpm3
call BuildFD.cmd ws4

echo :
echo : Building Hard Disk Images...
echo :
call BuildHD.cmd cpm22
call BuildHD.cmd zsdos
call BuildHD.cmd nzcom
call BuildHD.cmd cpm3
call BuildHD.cmd zpm3
call BuildHD.cmd ws4
