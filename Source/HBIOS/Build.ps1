param([string]$Platform = "", [string]$Config = "", [string]$RomSize = "512", [string]$RomName = "")

#
# This PowerShell script performs the heavy lifting in the build of RomWBW.  It handles the assembly
# of the HBIOS and then creates the final ROM image imbedding the other components such as the OS
# images, boot loader, and ROM disk image.
#
# The RomWBW build is heavily dependent on the concept of a hardware "platform" and the associated
# "configuration".  The build process selects a pair of files that are included in the HBIOS assembly
# to create the hardware-specific ROM image.  First, a platform file called cfg_<platform>.asm is
# included to establish the required assembly equates for the main hardware platform.  Second, a
# file from the Config subdirectory is included to tune the build for the specific setup of the
# desired hardware platform.  The platform file establishes all of the default equate values for
# the platform being built.  The config file is used to override the values in the platform file
# as desired.
#
# Note that there is a special platform called UNA.  UNA is John Coffman's hardware BIOS which is an
# alternative to HBIOS.  UNA is a single image that will run on all platforms and has a built-in
# setup mechanism so that multiple configuration are not needed.  When building for UNA, the pre-built
# UNA BIOS is simply imbedded, it is not built here.
#
$PlatformListZ80 = "SBC", "ZETA", "ZETA2", "RCZ80", "RCZ280", "EZZ80", "UNA"
$PlatformListZ180 = "N8", "MK4", "RCZ180", "SCZ180", "DYNO"

#
# Establish the build platform.  It may have been passed in on the command line.  Validate
# $Platform and loop requesting a new value as long as it is not valid.  The valid platform
# names are just hard-coded for now.
#
$PlatformList = $PlatformListZ80 + $PlatformListZ180
$Prompt = "Platform ["
ForEach ($PlatformName in $PlatformList) {$Prompt += $PlatformName + "|"}
$Prompt = $Prompt.Substring(0, $Prompt.Length - 1) + "]"
$Platform = $Platform.ToUpper()
while ($true)
{
	if ($PlatformList -contains $Platform) {break}
	$Platform = (Read-Host -prompt $Prompt).Trim().ToUpper()
}

#
# Establish the platform configuration to build.  It may have been passed in on the commandline.  Validate
# $Config and loop requesting a new value as long as it is not valid.  The file system is scanned to determine
# if the requested ConfigFile exists.  Config files must be named <platform>_<config>.asm where <platform> is
# the platform name established above and <config> is the value of $Config determined here.
#
while ($true)
{
	$PlatformConfigFile = "Config/plt_${Platform}.asm"
	$ConfigFile = "Config/${Platform}_${Config}.asm"
	if (Test-Path $ConfigFile) {break}
	if ($Config -ne "") {Write-Host "${ConfigFile} does not exist!"}

	"Configurations available:"
	Get-Item "Config/${Platform}_*.asm" | foreach {Write-Host " >", $_.Name.Substring($Platform.Length + 1, $_.Name.Length - $Platform.Length - 5)}
	$Config = (Read-Host -prompt "Configuration").Trim()
}

#
# Establish the ROM size (in KB).  It may have been passed in on the command line.  Validate
# $RomSize and loop requesting a new value as long as it is not valid.  The valid ROM sizes
# are just hard-coded for now.  The ROM size does nothing more than determine the size of the
# ROM disk portion of the ROM image.
#
while ($true)
{
	if (($RomSize -eq "512") -or ($RomSize -eq "1024")) {break}
	$RomSize = (Read-Host -prompt "ROM Size [512|1024]").Trim()
}

#
# TASM should be invoked with the proper CPU type.  Below, the CPU type is inferred
# from the platform.
#
if ($PlatformListZ180 -contains $Platform) {$CPUType = "180"} else {$CPUType = "80"}

#
# The $RomName variable determines the name of the image created by the script.  By default,
# this will be <platform>_<config>.rom.  Unless the script was invoked with a specified
# ROM filename, the name is established below.
#
if ($RomName -eq "") {$RomName = "${Platform}_${Config}"}
while ($RomName -eq "")
{
	$CP = (Read-Host -prompt "ROM Name [${Config}]").Trim()
	if ($RomName -eq "") {$RomName = $Config}
}

# If a PowerShell exception occurs, just stop the script immediately.
$ErrorAction = 'Stop'

# Directories of required build tools (TASM & cpmtools)
$TasmPath = '..\..\tools\tasm32'
$CpmToolsPath = '..\..\tools\cpmtools'

# Add tool directories to PATH and setup TASM's TABS directory path
$env:TASMTABS = $TasmPath
$env:PATH = $TasmPath + ';' + $CpmToolsPath + ';' + $env:PATH

# Initialize working variables
$OutDir = "../../Binary"		# Output directory for final image file
$RomFmt = "wbw_rom${RomSize}"		# Location of files to imbed in ROM disk
$BlankROM = "Blank${RomSize}KB.dat"	# An initial "empty" image for the ROM disk of propoer size
$RomDiskFile = "RomDisk.tmp"		# Temporary filename used to create ROM disk image
$RomFile = "${OutDir}/${RomName}.rom"	# Final name of ROM image
$ComFile = "${OutDir}/${RomName}.com"	# Final name of COM image (command line loadable HBIOS/CBIOS)
$ImgFile = "${OutDir}/${RomName}.img"	# Final name of IMG image (memory loadable HBIOS/CBIOS image)

# Select the proper CBIOS to include in the ROM.  UNA is special.
if ($Platform -eq "UNA") {$Bios = 'una'} else {$Bios = 'wbw'}

# List of RomWBW proprietary apps to imbed in ROM disk.
$RomApps = "assign","fdu","format","mode","rtc","survey","syscopy","sysgen","talk","timer","xm","inttest"

""
"Building ${RomName} ${ROMSize}KB ROM configuration ${Config} for Z${CPUType}..."
""

# Current date/time is queried here to be subsequently imbedded in image
$TimeStamp = '"' + (Get-Date -Format 'yyyy-MM-dd') + '"'

# Function to run TASM and throw an exception if an error occurs.
Function Asm($Component, $Opt, $Architecture=$CPUType, $Output="${Component}.bin", $List="${Component}.lst")
{
  $Cmd = "tasm -t${Architecture} -g3 -e ${Opt} ${Component}.asm ${Output} ${List}"
  $Cmd | write-host
  Invoke-Expression $Cmd | write-host
  if ($LASTEXITCODE -gt 0) {throw "TASM returned exit code $LASTEXITCODE"}
}

# Function to concatenate two binary files.
Function Concat($InputFileList, $OutputFile)
{
	Set-Content $OutputFile -Value $null
	foreach ($InputFile in $InputFileList)
	{
		Add-Content $OutputFile -Value ([System.IO.File]::ReadAllBytes($InputFile)) -Encoding byte
	}
}

#
# Since TASM has no mechanism to include files dynamically based on variables, a file
# is built on-the-fly here for imbedding in the build process.  This file is basically
# just used to include the platform and config files.  It also passes in some values
# from the build to include in the build.

@"
; RomWBW Configured for ${Platform} ${Config}, $(Get-Date -Format "s")
;
#DEFINE		TIMESTAMP	${TimeStamp}
;
ROMSIZE		.EQU		${ROMSize}
;
#INCLUDE "${ConfigFile}"
;
"@ | Out-File "build.inc" -Encoding ASCII

# # Bring over previously assembled binary copy of Forth for later use.
# Copy-Item '..\Forth\camel80.bin' 'camel80.bin'

# Bring over previously generated font files.
Copy-Item '..\Fonts\font*.asm' '.'

# Assemble individual components.  Note in the case of UNA, there is less to build.
$RomComponentList = "dbgmon", "romldr", "eastaegg", "imgpad"
ForEach ($RomComponentName in $RomComponentList) {Asm $RomComponentName}

if ($Platform -ne "UNA")
{
	Asm 'hbios' '-dROMBOOT' -Output 'hbios_rom.bin' -List 'hbios_rom.lst'
	Asm 'hbios' '-dAPPBOOT' -Output 'hbios_app.bin' -List 'hbios_app.lst'
	Asm 'hbios' '-dIMGBOOT' -Output 'hbios_img.bin' -List 'hbios_img.lst'
	
	Asm 'nascom'
	Asm 'tastybasic'
	Asm 'game'
	Asm 'usrrom'
	Asm 'imgpad0'
}

#
# Once all of the individual binary components have been created above, the final
# ROM image is created by simply concatenating the pieces together as needed.
#
"Building ${RomName} output files..."

# Build 32K OS chunk containing the loader, debug monitor, and two OS images
Concat 'romldr.bin', 'eastaegg.bin','dbgmon.bin', "..\cpm22\cpm_${Bios}.bin", "..\zsdos\zsys_${Bios}.bin" osimg.bin

# Build 20K OS chunk containing the loader, debug monitor, and one OS image
Concat 'romldr.bin', 'eastaegg.bin','dbgmon.bin', "..\zsdos\zsys_${Bios}.bin" osimg_small.bin

# Build second 32K chunk containing supplemental ROM apps (not for UNA)
if ($Platform -ne "UNA")
{
	Concat '..\Forth\camel80.bin', 'nascom.bin', 'tastybasic.bin', 'game.bin', 'imgpad0.bin', 'usrrom.bin' osimg1.bin
}

#
# Now the ROM disk image is created.  This is done by starting with a
# blank ROM disk image of the correct size, then cpmtools is used to
# add the desired files.
#

"Building ${RomSize}KB ${RomName} ROM disk data file..."

# Create a blank ROM disk image to create a working ROM disk image
Set-Content -Value ([byte[]](0xE5) * (([int]${RomSize} * 1KB) - 128KB)) -Encoding byte -Path $RomDiskFile

# Copy all files from the appropriate directory to the working ROM disk image
cpmcp -f $RomFmt $RomDiskFile ../RomDsk/ROM_${RomSize}KB/*.* 0:

# Add any platform specific files to the working ROM disk image
if (Test-Path "../RomDsk/${Platform}/*.*")
{
	cpmcp -f $RomFmt $RomDiskFile ../RomDsk/${Platform}/*.* 0:
}

# Add the proprietary RomWBW applications to the working ROM disk image
foreach ($App in $RomApps)
{
	cpmcp -f $RomFmt $RomDiskFile ../../Binary/Apps/$App.com 0:
}

# Add the CP/M and ZSystem system images to the ROM disk (used by SYSCOPY)
cpmcp -f $RomFmt $RomDiskFile ..\cpm22\cpm_${Bios}.sys 0:cpm.sys
cpmcp -f $RomFmt $RomDiskFile ..\zsdos\zsys_${Bios}.sys 0:zsys.sys

#
# Finally, the individual binary components are concatenated together to produce
# the final images.
#
if ($Platform -eq "UNA")
{
	Copy-Item 'osimg.bin' ${OutDir}\UNA_WBW_SYS.bin
	Copy-Item $RomDiskFile ${OutDir}\UNA_WBW_ROM${ROMSize}.bin

	Concat '..\UBIOS\UNA-BIOS.BIN','osimg.bin','..\UBIOS\FSFAT.BIN',$RomDiskFile $RomFile
}
else 
{
	Concat 'hbios_rom.bin','osimg.bin','osimg1.bin','osimg.bin',$RomDiskFile $RomFile
	Concat 'hbios_app.bin','osimg_small.bin' $ComFile
	# Concat 'hbios_img.bin','osimg_small.bin' $ImgFile
}

# Remove the temporary working ROM disk file
Remove-Item $RomDiskFile
