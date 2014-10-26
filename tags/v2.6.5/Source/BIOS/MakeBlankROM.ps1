# Create a "dummy" rom image, filled with hex E5
#
Set-Content -Value ([byte[]](0xE5) * (512KB - 64KB)) -Encoding byte -Path 'Blank512KB.dat'
Set-Content -Value ([byte[]](0xE5) * (1MB - 64KB)) -Encoding byte -Path 'Blank1024KB.dat'

Set-Content -Value ([byte[]](0xE5) * (512KB - 128KB)) -Encoding byte -Path 'Blank512KB-UNA.dat'
Set-Content -Value ([byte[]](0xE5) * (1MB - 128KB)) -Encoding byte -Path 'Blank1024KB-UNA.dat'

Set-Content -Value ([byte[]](0xE5) * (512KB - 160KB)) -Encoding byte -Path 'Blank512KB-UNALOAD.dat'
Set-Content -Value ([byte[]](0xE5) * (1MB - 160KB)) -Encoding byte -Path 'Blank1024KB-UNALOAD.dat'
