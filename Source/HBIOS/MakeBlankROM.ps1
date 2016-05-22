# Create a "blank" rom disk image, filled with hex E5
#
Set-Content -Value ([byte[]](0xE5) * (512KB - 128KB)) -Encoding byte -Path 'Blank512KB.dat'
Set-Content -Value ([byte[]](0xE5) * (1MB - 128KB)) -Encoding byte -Path 'Blank1024KB.dat'
