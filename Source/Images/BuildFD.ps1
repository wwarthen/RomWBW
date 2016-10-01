$ErrorAction = 'Stop'

$CpmToolsPath = '../..\Tools\cpmtools'

$env:PATH = $CpmToolsPath + ';' + $env:PATH

$Blank = ([byte[]](0xE5) * 1440KB)

"Creating work file..."
if (!(Test-Path('Blank.tmp'))) {Set-Content -Value $Blank -Encoding byte -Path 'Blank.tmp'}

"Creating floppy disk images..."
for ($Dsk=0; $Dsk -lt 2; $Dsk++)
{
	"Generating Floppy Disk ${Dsk}..."
	copy Blank.tmp fd${Dsk}.img
	for ($Usr=0; $Usr -lt 16; $Usr++)
	{
		if (Test-Path ("fd${Dsk}/u${Usr}/*")) 
		{
			$Cmd = "cpmcp -f wbw_fd144 fd${Dsk}.img fd${Dsk}/u${Usr}/*.* ${Usr}:"
			$Cmd
			Invoke-Expression $Cmd
		}
	}
}

"Moving images into output directory..."
&$env:COMSPEC /c move fd*.img ..\..\Binary\

Remove-Item *.tmp

return