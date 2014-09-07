param([string]$Platform = "", [string]$Config = "", [string]$RomSize = "", [string]$RomName = "")

$Platform = $Platform.ToUpper()
while ($true)
{
	if (($Platform -eq "N8VEM") -or ($Platform -eq "ZETA") -or ($Platform -eq "N8") -or ($Platform -eq "MK4") -or ($Platform -eq "UNA") -or ($Platform -eq "S2I") -or ($Platform -eq "S100")) {break}
	$Platform = (Read-Host -prompt "Platform [N8VEM|ZETA|N8|MK4|UNA|S2I|S100]").Trim().ToUpper()
}

while ($true)
{
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

if ($Platform -eq "UNA") {$BIOS = "ubios"} else {$BIOS = "hbios"}

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

$OutDir = "../../Output"
#$RomFmt = "wbw_rom${RomSize}"
if ($Platform -eq "UNA") {$RomFmt = "una_rom${RomSize}"} else {$RomFmt = "wbw_rom${RomSize}"}
if ($Platform -eq "UNA") {$BlankFile = "blank${RomSize}KB-UNA.dat"} else {$BlankFile = "blank${RomSize}KB.dat"}
$RomDiskFile = "RomDisk.tmp"
$RomFile = "${OutDir}/${RomName}.rom"
$CPMImgFile = "${OutDir}/${RomName}_CPM.sys"
$ZSYSImgFile = "${OutDir}/${RomName}_ZSYS.sys"
$CPMLoader = "${OutDir}/${RomName}_CPM.com"
$ZSYSLoader = "${OutDir}/${RomName}_ZSYS.com"

""
"Building ${RomName}: ${ROMSize}KB ROM configuration ${Config} for Z${CPUType}..."
""

$TimeStamp = '"' + (Get-Date -Format 'dd-MMM-yyyy') + '"'

Function Asm($Component, $Opt, $Architecture=$CPUType, $Output="${Component}.bin")
{
  $Cmd = "tasm -t${Architecture} -g3 ${Opt} ${Component}.asm ${Output}"
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
ROMSIZE		.EQU		${ROMSize}			; SIZE OF ROM IN KB
PLATFORM	.EQU		PLT_${Platform}		; HARDWARE PLATFORM
;
; INCLUDE PLATFORM SPECIFIC DEVICE DEFINITIONS
;
#INCLUDE "std-n8vem.inc"
;
#INCLUDE "${ConfigFile}"
;
"@ | Out-File "build.inc" -Encoding ASCII

Copy-Item '..\cpm22\os2ccp.bin' 'ccp.bin'
Copy-Item '..\cpm22\os3bdos.bin' 'bdos.bin'

Copy-Item '..\zcpr-dj\zcpr.bin' 'zcpr.bin'
Copy-Item '..\zsdos\zsdos.bin' 'zsdos.bin'

Asm 'syscfg'
Asm 'cbios' "-dBLD_SYS=SYS_CPM" -Output "cbios.bin"
Asm 'cbios' "-dBLD_SYS=SYS_ZSYS" -Output "zbios.bin"
Asm 'dbgmon'
Asm 'prefix'
Asm 'bootrom'
Asm 'bootapp'
Asm 'loader'
Asm 'pgzero'
Asm $BIOS
Asm 'hbfill'
Asm 'romfill'

# Generate result files using components above

"Building ${RomName} output files..."

Concat 'ccp.bin','bdos.bin','cbios.bin' 'cpm.bin'
Concat 'zcpr.bin','zsdos.bin','zbios.bin' 'zsys.bin'

Concat 'prefix.bin','cpm.bin' $CPMImgFile
Concat 'prefix.bin','zsys.bin' $ZSYSImgFile

Concat 'pgzero.bin','bootrom.bin','syscfg.bin','loader.bin','zsys.bin','hbfill.bin','dbgmon.bin','cpm.bin','hbfill.bin' 'rom1.bin'
Concat 'pgzero.bin','bootrom.bin','syscfg.bin','loader.bin',"${BIOS}.bin" 'rom2.bin'

Concat 'bootapp.bin','syscfg.bin','loader.bin',"${BIOS}.bin",'dbgmon.bin','cpm.bin' $CPMLoader
Concat 'bootapp.bin','syscfg.bin','loader.bin',"${BIOS}.bin",'dbgmon.bin','zsys.bin' $ZSYSLoader

# Create the RomDisk image

"Building ${RomSize}KB ${RomName} ROM disk data file..."

Copy-Item $BlankFile $RomDiskFile
cpmcp -f $RomFmt $RomDiskFile ../RomDsk/ROM_${RomSize}KB/*.* 0:
cpmcp -f $RomFmt $RomDiskFile ../RomDsk/${Platform}_${Config}/*.* 0:
cpmcp -f $RomFmt $RomDiskFile ../Apps/*.com 0:
cpmcp -f $RomFmt $RomDiskFile ${OutDir}/${RomName}_CPM.sys 0:CPM.sys
cpmcp -f $RomFmt $RomDiskFile ${OutDir}/${RomName}_ZSYS.sys 0:ZSYS.sys

if ($Platform -eq "UNA")
{
	Copy-Item 'rom1.bin' ${OutDir}\UNA_WBW_SYS.bin
	Copy-Item $RomDiskFile ${OutDir}\UNA_WBW_ROM${ROMSize}.bin

	Concat 'UNA\UNA-BIOS.BIN','rom1.bin','UNA\FSFAT.BIN',$RomDiskFile $RomFile
}
else 
{
	Concat 'rom1.bin','rom2.bin',$RomDiskFile $RomFile
}

# Cleanup
Remove-Item $RomDiskFile