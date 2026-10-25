# This PowerShell script will build a floppy disk or hard disk
# slice image based on the parameter passed in.  The single
# input parameter is the name of the desired image.  E.g.,
# hd1k_zsdos.img will build a zsdos slice image as defined in
# hd_zsdos.txt using the hd1k format.

param([string]$Image)

# If a PowerShell exception occurs, just stop the script immediately.
$ErrorAction = 'Stop'

$CpmToolsPath = '../../Tools/cpmtools'
$SRecordPath = '../../Tools/srecord'

$env:PATH = $CpmToolsPath + ';' + $SRecordPath + ';' + $env:PATH

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

# Ingest all @ prefixed directives in the disk configuratioun file

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

# Generate the empty disk image file

$Cmd = "srec_cat -generate 0x0 $Size -constant 0xE5 -o $ImgFile -Binary"
$Cmd
Invoke-Expression $Cmd

# Insert boot image if specified

if ($SysImage.Length -gt 0)
{
	$Cmd = "mkfs.cpm -f $Format $ImgFile -b $SysImage"
	$Cmd
	Invoke-Expression $Cmd
}

# Inject label into disk image if specified

if ($Label.Length -gt 0)
{
	$Offset = 0x5E7
	$Stream = New-Object System.IO.FileStream($ImgFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Write)
	$Label = $Label.Substring(0, [System.Math]::Min(16, $Label.Length))
	$Label = $Label.PadRight(17, '$')
	$Bytes = [System.Text.Encoding]::UTF8.GetBytes($Label)
	[void]$Stream.Seek($Offset, [System.IO.SeekOrigin]::Begin)
	$stream.Write($Bytes, 0, $Bytes.Length)
	$stream.Close()
}

# Copy all files in all user areas from associated disk directory into image

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

# Copy supplemental files based on instructions in the associated disk configuration file

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

# Dump a disk catalog for diagnostics

$Cmd = "cpmls -f $Format -D $ImgFile"
$Cmd
Invoke-Expression $Cmd > $CatFile

# Move the final image into the output directory

# "Moving image $ImgFile into output directory..."

Move-Item $ImgFile -Destination "..\..\Binary\" -Force

return
