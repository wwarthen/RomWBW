Param($Disk, $Format="wbw_fd144", $SysFile="")

$ErrorAction = 'Stop'

$ImgFile = "fd_${Disk}.img"
$MediaID = 6
$Size = 1440KB

$CpmToolsPath = '../../Tools/cpmtools'

$env:PATH = $CpmToolsPath + ';' + $env:PATH

if (-not (Test-Path("d_${Disk}/")))
{
	Write-Error "Source directory d_${Disk} for disk ${Disk} not found!" -ErrorAction Stop 
	return
}

"Generating Floppy Disk ${Disk}..."

if ($SysFile.Length -gt 0) 
	{ [byte[]]$SysImg = [System.IO.File]::ReadAllBytes($SysFile) }
else 
	{ [byte[]]$SysImg = @() }

$Image = ($SysImg + ([byte[]](0xE5) * ($Size - $SysImg.length)))

$Image[1410] = 0x4D
$Image[1411] = 0x49
$Image[1412] = 0x44
$Image[1413] = $MediaID

[System.IO.File]::WriteAllBytes($ImgFile, $Image)

for ($Usr=0; $Usr -lt 16; $Usr++)
{
	if (Test-Path ("d_${Disk}/u${Usr}/*")) 
	{
		$Cmd = "cpmcp -f $Format $ImgFile d_${Disk}/u${Usr}/*.* ${Usr}:"
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
			$Cmd = "cpmcp -f $Format $ImgFile ${Spec}"
			$Cmd
			Invoke-Expression $Cmd
		}
	}
}

"Moving image $ImgFile into output directory..."

Move-Item $ImgFile -Destination "..\..\Binary\" -Force

return