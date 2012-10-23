$ErrorAction = 'Stop'

$CpmToolsPath = '..\tools\cpmtools'

$env:PATH = $CpmToolsPath + ';' + $env:PATH

$OutDir = "../Output"
$ImgFile = "Disk.img"
$Blank = ([byte[]](0xE5) * (128KB * 65))

"Creating work file..."
Set-Content -Value $Blank -Encoding byte -Path Blank.img

"Creating output file..."
Set-Content -Path $ImgFile -Value $null

"Adding files to partition 0..."
copy Blank.img hd0.tmp
if (Test-Path ('hd0\*')) {cpmcp -f hd0 hd0.tmp hd0/*.* 0:}

copy /b hd*.tmp Disk.img

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