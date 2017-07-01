param([string]$Platform = "", [string]$Config = "", [string]$RomSize = "512", [string]$RomName = "")

$Platform = $Platform.ToUpper()
while ($true)
{
	if (($Platform -eq "SBC") -or ($Platform -eq "ZETA") -or ($Platform -eq "ZETA2") -or ($Platform -eq "N8") -or ($Platform -eq "MK4") -or ($Platform -eq "UNA")) {break}
	$Platform = (Read-Host -prompt "Platform [SBC|ZETA|ZETA2|N8|MK4|UNA]").Trim().ToUpper()
}

while ($true)
{
;	$PlatformConfigFile = "Config/plt_${Platform}.asm"
	$ConfigFile = "Config/${Platform}_${Config}.asm"
	if (Test-Path $ConfigFile) {break}
	if ($Config -ne "") {Write-Host "${ConfigFile} does not exist!"}

	"Configurations available:"
	Get-Item "Config/${Platform}_*.asm" | foreach {Write-Host " >", $_.Name.Substring($Platform.Length + 1, $_.Name.Length - $Platform.Length - 5)}
	$Config = (Read-Host -prompt "Configuration").Trim()
}

while ($true)
{
	if (($RomSize -eq "512") -or ($RomSize -eq "1024")) {break}
	$RomSize = (Read-Host -prompt "ROM Size [512|1024]").Trim()
}

if (($Platform -eq "N8") -or ($Platform -eq "MK4")) {$CPUType = "180"} else {$CPUType = "80"}

if ($RomName -eq "") {$RomName = "${Platform}_${Config}"}
while ($RomName -eq "")
{
	$CP = (Read-Host -prompt "ROM Name [${Config}]").Trim()
	if ($RomName -eq "") {$RomName = $Config}
}

$ErrorAction = 'Stop'

$TasmPath = '..\..\tools\tasm32'
$CpmToolsPath = '..\..\tools\cpmtools'

$env:TASMTABS = $TasmPath
$env:PATH = $TasmPath + ';' + $CpmToolsPath + ';' + $env:PATH

$OutDir = "../../Binary"
$RomFmt = "wbw_rom${RomSize}"
$BlankROM = "Blank${RomSize}KB.dat"
$RomDiskFile = "RomDisk.tmp"
$RomFile = "${OutDir}/${RomName}.rom"
$ComFile = "${OutDir}/${RomName}.com"
$ImgFile = "${OutDir}/${RomName}.img"
if ($Platform -eq "UNA") {$CBiosFile = '../CBIOS/cbios_una.bin'} else {$CBiosFile = '../CBIOS/cbios_wbw.bin'}

""
"Building ${RomName}: ${ROMSize}KB ROM configuration ${Config} for Z${CPUType}..."
""

# $TimeStamp = '"' + (Get-Date -Format 'dd-MMM-yyyy') + '"'
$TimeStamp = '"' + (Get-Date -Format 'yyyy-MM-dd') + '"'

Function Asm($Component, $Opt, $Architecture=$CPUType, $Output="${Component}.bin", $List="${Component}.lst")
{
  $Cmd = "tasm -t${Architecture} -g3 ${Opt} ${Component}.asm ${Output} ${List}"
  $Cmd | write-host
  Invoke-Expression $Cmd | write-host
  if ($LASTEXITCODE -gt 0) {throw "TASM returned exit code $LASTEXITCODE"}
}

Function Concat($InputFileList, $OutputFile)
{
	Set-Content $OutputFile -Value $null
	foreach ($InputFile in $InputFileList)
	{
		Add-Content $OutputFile -Value ([System.IO.File]::ReadAllBytes($InputFile)) -Encoding byte
	}
}

# Generate the build settings include file

@"
; RomWBW Configured for ${Platform} ${Config}, $(Get-Date -Format "s")
;
#DEFINE		TIMESTAMP	${TimeStamp}
;
PLATFORM	.EQU		PLT_${Platform}		; HARDWARE PLATFORM
ROMSIZE		.EQU		${ROMSize}		; SIZE OF ROM IN KB
;
;#INCLUDE "${PlatformConfigFile}"
#INCLUDE "${ConfigFile}"
;
"@ | Out-File "build.inc" -Encoding ASCII

Copy-Item '..\cpm22\os2ccp.bin' 'ccp.bin'
Copy-Item '..\cpm22\os3bdos.bin' 'bdos.bin'

Copy-Item '..\zcpr-dj\zcpr.bin' 'zcpr.bin'
Copy-Item '..\zsdos\zsdos.bin' 'zsdos.bin'

Asm 'dbgmon'
Asm 'prefix'
Asm 'romldr'
if ($Platform -ne "UNA")
{
	Asm 'hbios' '-dROMBOOT' -Output 'hbios_rom.bin' -List 'hbios_rom.lst'
	Asm 'hbios' '-dAPPBOOT' -Output 'hbios_app.bin' -List 'hbios_app.lst'
	Asm 'hbios' '-dIMGBOOT' -Output 'hbios_img.bin' -List 'hbios_img.lst'
}

# Generate result files using components above

"Building ${RomName} output files..."

Concat 'ccp.bin','bdos.bin',$CBiosFile 'cpm.bin'
Concat 'zcpr.bin','zsdos.bin',$CBiosFile 'zsys.bin'

Concat 'prefix.bin','cpm.bin' 'cpm.sys'
Concat 'prefix.bin','zsys.bin' 'zsys.sys'

Concat 'romldr.bin', 'dbgmon.bin','cpm.bin','zsys.bin' osimg.bin

# Create the RomDisk image

"Building ${RomSize}KB ${RomName} ROM disk data file..."

Copy-Item $BlankROM $RomDiskFile
cpmcp -f $RomFmt $RomDiskFile ../RomDsk/ROM_${RomSize}KB/*.* 0:
#cpmcp -f $RomFmt $RomDiskFile ../RomDsk/${Platform}_${Config}/*.* 0:
cpmcp -f $RomFmt $RomDiskFile ../RomDsk/${Platform}/*.* 0:
cpmcp -f $RomFmt $RomDiskFile ../Apps/*.com 0:
cpmcp -f $RomFmt $RomDiskFile *.sys 0:

if ($Platform -eq "UNA")
{
	Copy-Item 'osimg.bin' ${OutDir}\UNA_WBW_SYS.bin
	Copy-Item $RomDiskFile ${OutDir}\UNA_WBW_ROM${ROMSize}.bin

	Concat '..\UBIOS\UNA-BIOS.BIN','osimg.bin','..\UBIOS\FSFAT.BIN',$RomDiskFile $RomFile
}
else 
{
	Concat 'hbios_rom.bin','osimg.bin','osimg.bin','osimg.bin',$RomDiskFile $RomFile
	Concat 'hbios_app.bin','osimg.bin' $ComFile
	Concat 'hbios_img.bin','osimg.bin' $ImgFile
}

# Cleanup

Remove-Item $RomDiskFile