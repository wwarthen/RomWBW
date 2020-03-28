#Param([Parameter(Mandatory)]$Disk, $SysFile="")
Param($Disk, $SysFile="")

$ErrorAction = 'Stop'

$ImgFile = "hd_${Disk}.img"
$Fmt = "wbw_hd0"
$Size = (128KB * 65)

$CpmToolsPath = '../../Tools/cpmtools'

$env:PATH = $CpmToolsPath + ';' + $env:PATH

if (-not (Test-Path("d_${Disk}/")))
{
	"Source directory d_${Disk} for disk ${Disk} not found!"
	return
}

"Generating Hard Disk ${Disk}..."

#$Blank = ([string]([char]0xE5)) * $Size
#Set-Content -Value $Blank -NoNewLine -Path $ImgFile
$Blank = ([byte[]](0xE5) * $Size)
[System.IO.File]::WriteAllBytes($ImgFile, $Blank)

if ($SysFile.Length -gt 0)
{
	"Adding System Image $SysFile..."
	#$Sys = Get-Content -Path "$SysFile.sys" -Raw
	#$Img = Get-Content -Path $ImgFile -Raw
	#$NewImg = $Sys + $Img.SubString($Sys.Length, $Img.Length - $Sys.Length)
	#Set-Content -NoNewLine -Path $ImgFile $NewImg
	
	$Cmd = "mkfs.cpm -f $Fmt -b $SysFile $ImgFile"
	$Cmd
	Invoke-Expression $Cmd
}

for ($Usr=0; $Usr -lt 16; $Usr++)
{
	if (Test-Path ("d_${Disk}/u${Usr}/*")) 
	{
		$Cmd = "cpmcp -f $Fmt $ImgFile d_${Disk}/u${Usr}/*.* ${Usr}:"
		$Cmd
		Invoke-Expression $Cmd
	}
}

if (Test-Path("d_${Disk}.txt"))
{
	foreach($Line in Get-Content "d_${Disk}.txt")
	{
		$Spec = $Line.Trim()
		if (($Spec.Length -gt 0) -and ($Spec.Substring(0,1) -ne "#"))
		{
			$Cmd = "cpmcp -f $Fmt $ImgFile ${Spec}"
			$Cmd
			Invoke-Expression $Cmd
		}
	}
}

"Moving image $ImgFile into output directory..."

#&$env:COMSPEC /c move $ImgFile ..\..\Binary\
Move-Item $ImgFile -Destination "..\..\Binary\" -Force

return