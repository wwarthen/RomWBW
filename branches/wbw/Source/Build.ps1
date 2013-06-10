param([string]$Platform = "", [string]$Config = "", [string]$RomSize = "", [string]$SYS = "", [string]$RomName = "")

$Platform = $Platform.ToUpper()
while ($true)
{
	if (($Platform -eq "N8VEM") -or ($Platform -eq "ZETA") -or ($Platform -eq "N8") -or ($Platform -eq "S2I") -or ($Platform -eq "S100")) {break}
	$Platform = (Read-Host -prompt "Platform [N8VEM|ZETA|N8|S2I|S100]").Trim().ToUpper()
}

while ($true)
{
	$ConfigFile = "config_${Platform}_${Config}.asm"
	if (Test-Path $ConfigFile) {break}
	if ($Config -ne "") {Write-Host "${ConfigFile} does not exist!"}

	"Configurations available:"
	Get-Item "config_${Platform}_*.asm" | foreach {Write-Host " >", $_.Name.Substring(8 + $Platform.Length, $_.Name.Length - 12 - $Platform.Length)}
	$Config = (Read-Host -prompt "Configuration").Trim()
}

while ($true)
{
	if (($RomSize -eq "512") -or ($RomSize -eq "1024")) {break}
	$RomSize = (Read-Host -prompt "ROM Size [512|1024]").Trim()
}

if ($Platform -eq "N8") {$CPUType = "180"} else {$CPUType = "80"}

$SYS = $SYS.ToUpper()
while ($true)
{
	if (($SYS -eq "CPM") -or ($SYS -eq "ZSYS")) {break}
	$SYS = (Read-Host -prompt "System [CPM|ZSYS]").Trim().ToUpper()
}

if ($RomName -eq "") {$RomName = "${Platform}_${Config}"}
while ($RomName -eq "")
{
	$CP = (Read-Host -prompt "ROM Name [${Config}]").Trim()
	if ($RomName -eq "") {$RomName = $Config}
}

$ErrorAction = 'Stop'

$TasmPath = '..\tools\tasm32'
$CpmToolsPath = '..\tools\cpmtools'

$env:TASMTABS = $TasmPath
$env:PATH = $TasmPath + ';' + $CpmToolsPath + ';' + $env:PATH

$OutDir = "../Output"
$RomFmt = "rom${RomSize}KB"
$BlankFile = "blank${RomSize}KB.dat"
$RomDiskFile = "RomDisk.tmp"
$RomFile = "${OutDir}/${RomName}.rom"
$SysImgFile = "${OutDir}/${RomName}.sys"
$LoaderFile = "${OutDir}/${RomName}.com"

""
"Building ${RomName}: ${ROMSize}KB ROM configuration ${Config} for Z${CPUType}..."
""

$TimeStamp = '"' + (Get-Date -Format 'yyMMddThhmm') + '"'
$Variant = '"RomWBW-' + $Env:UserName + '"'

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
; RomWBW Configured for ${Platform} ${Config}, $(Get-Date)
;
#DEFINE		TIMESTAMP	${TimeStamp}
#DEFINE		VARIANT		${Variant}
;
ROMSIZE		.EQU		${ROMSize}		; SIZE OF ROM IN KB
PLATFORM	.EQU		PLT_${Platform}		; HARDWARE PLATFORM
;
; INCLUDE PLATFORM SPECIFIC DEVICE DEFINITIONS
;
#IF (PLATFORM == PLT_S100)
  #INCLUDE "std-s100.inc"
#ELSE
  #INCLUDE "std-n8vem.inc"
#ENDIF
;
#INCLUDE "${ConfigFile}"
;
"@ | Out-File "build.inc" -Encoding ASCII

# Build components

if ($SYS -eq "CPM")
{
	Asm 'ccpb03' -Output 'cp.bin'
	Asm 'bdosb01' -Output 'dos.bin'
}
if ($SYS -eq "ZSYS")
{
	Asm 'zcprw' -Architecture '85' -Output 'cp.bin'
	Asm 'zsdos' -Output 'dos.bin'
}

Asm 'syscfg'
Asm 'cbios' "-dBLD_SYS=SYS_${SYS}"
Asm 'dbgmon'
Asm 'prefix'
Asm 'bootrom'
Asm 'bootapp'
Asm 'loader'
Asm 'pgzero'
Asm 'hbios'
Asm 'hbfill'
Asm 'romfill'

# Generate result files using components above

"Building ${RomName} output files..."

Concat 'cp.bin','dos.bin','cbios.bin' 'os.bin'
Concat 'prefix.bin','os.bin' $SysImgFile
Concat 'pgzero.bin','bootrom.bin','syscfg.bin','loader.bin','romfill.bin','dbgmon.bin','os.bin','hbfill.bin' 'rom0.bin'
Concat 'pgzero.bin','bootrom.bin','syscfg.bin','loader.bin','hbios.bin' 'rom1.bin'
Concat 'bootapp.bin','syscfg.bin','loader.bin','hbios.bin','dbgmon.bin','os.bin' $LoaderFile

# Create the RomDisk image

"Building ${RomSize}KB ${RomName} ROM disk data file..."

Copy-Item $BlankFile $RomDiskFile
cpmcp -f $RomFmt $RomDiskFile ../RomDsk/${SYS}_${RomSize}KB/*.* 0:
cpmcp -f $RomFmt $RomDiskFile ../RomDsk/cfg_${Platform}_${Config}/*.* 0:
cpmcp -f $RomFmt $RomDiskFile ../Apps/Output/*.* 0:
cpmcp -f $RomFmt $RomDiskFile ../Output/${RomName}.sys 0:${SYS}.sys

Concat 'rom0.bin','rom1.bin',$RomDiskFile $RomFile

# Cleanup
Remove-Item $RomDiskFile