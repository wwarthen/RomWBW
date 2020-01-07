$ErrorAction = 'Stop'

$CpmToolsPath = '../../Tools/cpmtools'

$env:PATH = $CpmToolsPath + ';' + $env:PATH

$Blank = ([byte[]](0xE5) * 1440KB)

"Creating work file..."
if (!(Test-Path('Blank.tmp'))) {Set-Content -Value $Blank -Encoding byte -Path 'Blank.tmp'}

"Creating floppy disk images..."
foreach ($Dsk in @("cpm3","cpm22","nzcom","ws4","zpm3","zsdos"))
{
	"Generating Floppy Disk ${Dsk}..."
	copy "Blank.tmp" "fd_${Dsk}.img"
	for ($Usr=0; $Usr -lt 16; $Usr++)
	{
		if (Test-Path ("d_${Dsk}/u${Usr}/*")) 
		{
			$Cmd = "cpmcp -f wbw_fd144 fd_${Dsk}.img d_${Dsk}/u${Usr}/*.* ${Usr}:"
			$Cmd
			Invoke-Expression $Cmd
		}
	}
}

"Moving images into output directory..."
&$env:COMSPEC /c move fd_*.img ..\..\Binary\

Remove-Item *.tmp

return