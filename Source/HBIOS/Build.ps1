param([string]$Platform = "", [string]$Config = "", [string]$ROMName = "")

# If a PowerShell exception occurs, just stop the script immediately.
$ErrorAction = 'Stop'

# This PowerShell script is used to prepare the build environment for
# HBIOS.  It starts by validating and/or prompting the user for several
# key variables that control the build: Platform, Config, ROM size, and
# optionally an override for the output ROM name.  These variables are
# then placed in a generated batch command file allowing them to be
# exposed to the subsequent build steps.  Next, it generates a
# small TASM include file that exposes some variables to the subsequent
# assembly process.
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

$PlatformListZ80 = "SBC", "MBC", "ZETA", "ZETA2", "RCZ80", "EZZ80", "UNA"
$PlatformListZ180 = "N8", "MK4", "RCZ180", "SCZ180", "DYNO", "RPH"
$PlatformListZ280 = "RCZ280"

#
# Establish the build platform.  It may have been passed in on the command line.  Validate
# $Platform and loop requesting a new value as long as it is not valid.  The valid platform
# names are just hard-coded for now.
#

$PlatformList = $PlatformListZ80 + $PlatformListZ180 + $PlatformListZ280
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
# TASM should be invoked with the proper CPU type.  Below, the CPU type is inferred
# from the platform.
#

$CPUType = "80"
if ($PlatformListZ180 -contains $Platform) {$CPUType = "180"}
if ($PlatformListZ280 -contains $Platform) {$CPUType = "280"}

#
# The $ROMName variable determines the name of the image created by the script.  By default,
# this will be <platform>_<config>.rom.  Unless the script was invoked with a specified
# ROM filename, the name is established below.
#

if ($ROMName -eq "") {$ROMName = "${Platform}_${Config}"}
while ($ROMName -eq "")
{
	$CP = (Read-Host -prompt "ROM Name [${Config}]").Trim()
	if ($ROMName -eq "") {$ROMName = $Config}
}

# Current date/time is queried here to be subsequently imbedded in image
$TimeStamp = (Get-Date -Format 'yyyy-MM-dd')

#
# Since TASM has no mechanism to include files dynamically based on variables, a file
# is built on-the-fly here for imbedding in the build process.  This file is basically
# just used to include the platform and config files.  It also passes in some values
# from the build to include in the assembly.
#

@"
; RomWBW Configured for ${Platform} ${Config}, $(Get-Date -Format "s")
;
#DEFINE		TIMESTAMP	"${TimeStamp}"
#DEFINE		CONFIG		"${Platform}_${Config}"
;
#INCLUDE "${ConfigFile}"
;
"@ | Out-File "build.inc" -Encoding ASCII

#
# We need to pass the key variables controling the assembly process back
# out to the calling batch file.  We do this by generating a small
# batch file which can be invoked by the calling batch file to expose
# the variables.
#

@"
set Platform=${Platform}
set Config=${Config}
set ROMName=${ROMName}
set CPUType=${CPUType}
"@ | Out-File "build_env.cmd" -Encoding ASCII
