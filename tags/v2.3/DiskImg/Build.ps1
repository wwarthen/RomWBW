$ErrorAction = 'Stop'

$CpmToolsPath = '..\tools\cpmtools'

$env:PATH = $CpmToolsPath + ';' + $env:PATH

$ImgFile = "..\Output\Disk.img"
$Blank = ([byte[]](0xE5) * (128KB * 65))

"Creating work file..."
if (!(Test-Path('Blank.tmp'))) {Set-Content -Value $Blank -Encoding byte -Path 'Blank.tmp'}

"Adding files to partition 0..."
copy Blank.tmp hd0.tmp
if (Test-Path ('hd0\*')) {cpmcp -f hd0 hd0.tmp hd0/*.* 0:}

"Adding files to partition 1..."
copy Blank.tmp hd1.tmp
if (Test-Path ('hd1\*')) {cpmcp -f hd0 hd1.tmp hd1/*.* 0:}

"Adding files to partition 2..."
copy Blank.tmp hd2.tmp
if (Test-Path ('hd2\*')) {cpmcp -f hd0 hd2.tmp hd2/*.* 0:}

"Adding files to partition 3..."
copy Blank.tmp hd3.tmp
if (Test-Path ('hd3\*')) {cpmcp -f hd0 hd3.tmp hd3/*.* 0:}

"Adding slices to image..."
#gc hd0.tmp -Enc Byte -Read 512 | Add-Content -Enc Byte $ImgFile 
#gc hd0.tmp -Enc Byte -Read 10240 | sc x.x -Enc Byte
&$env:COMSPEC /c copy /b hd*.tmp $ImgFile

Remove-Item *.tmp

return

"Adding files to partition 0..."
Set-Content -Value $Blank -Encoding byte -Path hd.img
if (Test-Path ('hd0\*')) {cpmcp -f hd0 hd.img hd0/*.* 0:}
Add-Content $ImgFile -Value ([System.IO.File]::ReadAllBytes('hd.img')) -Encoding byte

"Adding files to partition 1..."
Set-Content -Value ([byte[]](0xE5) * (128KB * 65)) -Encoding byte -Path hd.img
if (Test-Path ('hd1\*')) {cpmcp -f hd0 hd.img hd1/*.* 0:}
Add-Content $ImgFile -Value ([System.IO.File]::ReadAllBytes('hd.img')) -Encoding byte

"Adding files to partition 2..."
Set-Content -Value ([byte[]](0xE5) * (128KB * 65)) -Encoding byte -Path hd.img
if (Test-Path ('hd2\*')) {cpmcp -f hd0 hd.img hd2/*.* 0:}
Add-Content $ImgFile -Value ([System.IO.File]::ReadAllBytes('hd.img')) -Encoding byte

"Adding files to partition 3..."
Set-Content -Value ([byte[]](0xE5) * (128KB * 65)) -Encoding byte -Path hd.img
if (Test-Path ('hd3\*')) {cpmcp -f hd0 hd.img hd3/*.* 0:}
Add-Content $ImgFile -Value ([System.IO.File]::ReadAllBytes('hd.img')) -Encoding byte

return