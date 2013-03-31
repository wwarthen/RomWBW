$ErrorAction = 'Stop'

$CpmToolsPath = '..\tools\cpmtools'

$env:PATH = $CpmToolsPath + ';' + $env:PATH

$ImgFile = "hd.img"
$Blank = ([byte[]](0xE5) * (128KB * 65))

"Creating work file..."
if (!(Test-Path('Blank.tmp'))) {Set-Content -Value $Blank -Encoding byte -Path 'Blank.tmp'}

for ($Dsk=0; $Dsk -lt 4; $Dsk++)
{
	"Adding files to disk ${Dsk}..."
	copy Blank.tmp hd${Dsk}.tmp
	for ($Usr=0; $Usr -lt 16; $Usr++)
	{
		if (Test-Path ("hd${Dsk}\u${Usr}\*")) 
		{
			$Cmd = "cpmcp -f hd0 hd${Dsk}.tmp hd${Dsk}/u${Usr}/*.* ${Usr}:"
			$Cmd
			Invoke-Expression $Cmd
		}
	}
}

"Adding disks to image..."
&$env:COMSPEC /c copy /b hd*.tmp $ImgFile

Remove-Item *.tmp

return