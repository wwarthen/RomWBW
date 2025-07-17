param([string]$Image)

# If a PowerShell exception occurs, just stop the script immediately.
$ErrorAction = 'Stop'

$CpmToolsPath = '../../Tools/cpmtools'

$env:PATH = $CpmToolsPath + ';' + $env:PATH

$Format, $Disk = $Image.Split("_")

$Format = "wbw_" + $Format

if ($Format.Length -eq 0)
{
	Write-Error "No disk format specified!" -ErrorAction Stop
	return
}

switch ($Format)
{
	"wbw_fd144"
	{
		# 1.44MB Floppy Disk
		$Type = "fd"
		$Desc = "1.44MB Floppy Disk"
		$ImgFile = "fd144_${Disk}.img"
		$CatFile = "fd144_${Disk}.cat"
		$MediaID = 6
		$Size = 1440KB
	}

	"wbw_hd512"
	{
		# 512 Directory Entry Hard Disk Format
		$Type = "hd"
		$Desc = "Hard Disk (512 directory entry format)"
		$ImgFile = "hd512_${Disk}.img"
		$CatFile = "hd512_${Disk}.cat"
		$MediaID = 4
		$Size = 8MB + 128KB
	}

	"wbw_hd1k"
	{
		# 1024 Directory Entry Hard Disk Format
		$Type = "hd"
		$Desc = "Hard Disk (1024 directory entry format)"
		$ImgFile = "hd1k_${Disk}.img"
		$CatFile = "hd1k_${Disk}.cat"
		$MediaID = 10
		$Size = 8MB
	}
}

if (-not (Test-Path("d_${Disk}/")))
{
	Write-Error "Source directory d_${Disk} for disk ${Disk} not found!" -ErrorAction Stop 
	return
}

"Generating $Disk $Desc..."

if (Test-Path("${Type}_${Disk}.txt"))
{
	foreach($Line in Get-Content "${Type}_${Disk}.txt")
	{
		$Spec = $Line.Trim()
		if (($Spec.Length -gt 0) -and ($Spec.Substring(0,1) -eq '@'))
		{
			$Directive = $Spec.Substring(1);
			$VarName, $VarVal = $Directive.Split("=")
			Invoke-Expression "`$$VarName = $VarVal"
			continue
		}
	}
}

# "Label: '$Label'"
# "SysImage: '$SysImage'"

if ($SysImage.Length -gt 0) 
	{ [byte[]]$SysImg = [System.IO.File]::ReadAllBytes($SysImage) }
else 
	{ [byte[]]$SysImg = @() }

$ImageBin = ($SysImg + ([byte[]](0xE5) * ($Size - $SysImg.length)))

if ($Label.Length -gt 0)
{
	$LabelBytes = [System.Text.Encoding]::ASCII.GetBytes($Label)
	$nLabel = 0;
	for ($nImg = 0x5E7; $nImg -lt 0x5F7; $nImg++)
	{
		if ($nLabel -lt $Label.Length)
		{
			$ImageBin[$nImg] = $LabelBytes[$nLabel]
		}
		else
		{
			$ImageBin[$nImg] = [byte][char]'$'
		}
		$nLabel++
	}
	$ImageBin[0x5F7] = [byte][char]'$'
}

[System.IO.File]::WriteAllBytes($ImgFile, $ImageBin)

for ($Usr=0; $Usr -lt 16; $Usr++)
{
	if (Test-Path ("d_${Disk}/u${Usr}/*")) 
	{
		$Cmd = "cpmcp -f $Format $ImgFile d_${Disk}/u${Usr}/*.* ${Usr}:"
		$Cmd
		Invoke-Expression $Cmd
		if ($LASTEXITCODE -gt 0) {throw "Command returned exit code $LASTEXITCODE"}
	}
}

if (Test-Path("${Type}_${Disk}.txt"))
{
	foreach($Line in Get-Content "${Type}_${Disk}.txt")
	{
		$Spec = $Line.Trim()
		if (($Spec.Length -gt 0) -and ($Spec.Substring(0,1) -ne "#") -and ($Spec.Substring(0,1) -ne "@"))
		{
			$Cmd = "cpmcp -f $Format $ImgFile ${Spec}"
			$Cmd
			Invoke-Expression $Cmd
			if ($LASTEXITCODE -gt 0) {throw "Command returned exit code $LASTEXITCODE"}
		}
	}
}

$Cmd = "cpmls -f $Format -D $ImgFile"
$Cmd
Invoke-Expression $Cmd > $CatFile

# "Moving image $ImgFile into output directory..."

Move-Item $ImgFile -Destination "..\..\Binary\" -Force

return
