@echo off
setlocal

echo :
echo : Cleaning...
echo :
call Clean.cmd
echo :
echo : Building Floppy Disk Images...
echo :
call BuildFD.cmd
echo :
echo : Building Hard Disk Images...
echo :
call BuildHD.cmd
