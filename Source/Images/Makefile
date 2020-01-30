OBJECTS =
TOOLS = ../../Tools
include $(TOOLS)/Makefile.inc

# cbios_wbw.bin: cbios.asm 
# 	$(TASM) -DPLTWBW -o $@ -l cbios_wbw.lst $<
# 
# cbios_una.bin: cbios.asm
# 	$(TASM) -DPLTUNA -o $@ -l cbios_una.lst $<
# 
# @echo off
# setlocal
# 
# echo :
# echo : Cleaning...
# echo :
# call Clean.cmd
# echo :
# echo : Building Floppy Disk Images...
# echo :
# call BuildFD.cmd
# echo :
# echo : Building Hard Disk Images...
# echo :
# call BuildHD.cmd
# @PowerShell -ExecutionPolicy Unrestricted .\BuildFD.ps1 %*@PowerShell -ExecutionPolicy Unrestricted .\BuildHD.ps1 %*@echo off
# setlocal
# 
# if exist *.tmp del *.tmp
# if exist *.img del *.img
# $ErrorAction = 'Stop'
# 
# $CpmToolsPath = '../..\Tools\cpmtools'
# 
# $env:PATH = $CpmToolsPath + ';' + $env:PATH
# 
# $Blank = ([byte[]](0xE5) * 1440KB)
# 
# "Creating work file..."
# if (!(Test-Path('Blank.tmp'))) {Set-Content -Value $Blank -Encoding byte -Path 'Blank.tmp'}
# 
# "Creating floppy disk images..."
# for ($Dsk=0; $Dsk -lt 2; $Dsk++)
# {
# 	"Generating Floppy Disk ${Dsk}..."
# 	copy Blank.tmp fd${Dsk}.img
# 	for ($Usr=0; $Usr -lt 16; $Usr++)
# 	{
# 		if (Test-Path ("fd${Dsk}/u${Usr}/*")) 
# 		{
# 			$Cmd = "cpmcp -f wbw_fd144 fd${Dsk}.img fd${Dsk}/u${Usr}/*.* ${Usr}:"
# 			$Cmd
# 			Invoke-Expression $Cmd
# 		}
# 	}
# }
# 
# "Moving images into output directory..."
# &$env:COMSPEC /c move fd*.img ..\..\Binary\
# 
# Remove-Item *.tmp
# 
# return$ErrorAction = 'Stop'
# 
# $CpmToolsPath = '../../Tools/cpmtools'
# 
# $env:PATH = $CpmToolsPath + ';' + $env:PATH
# 
# $Blank = ([byte[]](0xE5) * (128KB * 65))
# 
# "Creating work file..."
# if (!(Test-Path('Blank.tmp'))) {Set-Content -Value $Blank -Encoding byte -Path 'Blank.tmp'}
# 
# "Creating hard disk images..."
# #for ($Dsk=0; $Dsk -lt 2; $Dsk++)
# foreach ($Dsk in @("hd0","hd1","hd_cpm3"))
# {
# 	"Generating Hard Disk ${Dsk}..."
# 	for ($Slice=0; $Slice -lt 4; $Slice++)
# 	{
# 		"Adding files to slice ${Slice}..."
# 		copy Blank.tmp slice${Slice}.tmp
# 		for ($Usr=0; $Usr -lt 16; $Usr++)
# 		{
# 			if (Test-Path ("${Dsk}/s${Slice}/u${Usr}/*")) 
# 			{
# 				$Cmd = "cpmcp -f wbw_hd0 slice${Slice}.tmp ${Dsk}/s${Slice}/u${Usr}/*.* ${Usr}:"
# 				$Cmd
# 				Invoke-Expression $Cmd
# 			}
# 		}
# 	}
# 
# 	"Combining slices into final disk image ${Dsk}..."
# 	&$env:COMSPEC /c copy /b slice*.tmp ..\..\Binary\${Dsk}.img
# 	
# 	Remove-Item slice*.tmp
# }
# 
# Remove-Item *.tmp
# 
# return
