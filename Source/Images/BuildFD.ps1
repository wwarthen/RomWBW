Param([Parameter(Mandatory)]$Disk)

$ErrorAction = 'Stop'

if (-not (Test-Path("d_${Disk}/")))
{
	"Source directory d_${Disk} for disk ${Disk} not found!"
	return
}

$CpmToolsPath = '../../Tools/cpmtools'

$env:PATH = $CpmToolsPath + ';' + $env:PATH

"Generating Floppy Disk ${Disk}..."

$Blank = ([string]([char]0xE5)) * 1440KB
Set-Content -Value $Blank -NoNewLine -Path "fd_${Disk}.img"

for ($Usr=0; $Usr -lt 16; $Usr++)
{
	if (Test-Path ("d_${Disk}/u${Usr}/*")) 
	{
		$Cmd = "cpmcp -f wbw_fd144 fd_${Disk}.img d_${Disk}/u${Usr}/*.* ${Usr}:"
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
			$Cmd = "cpmcp -f wbw_fd144 fd_${Disk}.img ${Spec}"
			$Cmd
			Invoke-Expression $Cmd
		}
	}
}

"Moving image fd_${Disk}.img into output directory..."

&$env:COMSPEC /c move fd_${Disk}.img ..\..\Binary\

return