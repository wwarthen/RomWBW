$ErrorAction = 'Stop'

$CpmToolsPath = '../../Tools/cpmtools'

$env:PATH = $CpmToolsPath + ';' + $env:PATH

$Blank = ([byte[]](0xE5) * (128KB * 65))

"Creating work file..."
if (!(Test-Path('Blank.tmp'))) {Set-Content -Value $Blank -Encoding byte -Path 'Blank.tmp'}

"Creating hard disk images..."
#for ($Dsk=0; $Dsk -lt 2; $Dsk++)
foreach ($Dsk in @("hd0","hd1","hd_cpm3","hd_zpm3"))
{
	"Generating Hard Disk ${Dsk}..."
	for ($Slice=0; $Slice -lt 4; $Slice++)
	{
		"Adding files to slice ${Slice}..."
		copy Blank.tmp slice${Slice}.tmp
		for ($Usr=0; $Usr -lt 16; $Usr++)
		{
			if (Test-Path ("${Dsk}/s${Slice}/u${Usr}/*")) 
			{
				$Cmd = "cpmcp -f wbw_hd0 slice${Slice}.tmp ${Dsk}/s${Slice}/u${Usr}/*.* ${Usr}:"
				$Cmd
				Invoke-Expression $Cmd
			}
		}
	}

	"Combining slices into final disk image ${Dsk}..."
	&$env:COMSPEC /c copy /b slice*.tmp ..\..\Binary\${Dsk}.img
	
	Remove-Item slice*.tmp
}

Remove-Item *.tmp

return