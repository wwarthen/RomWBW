# Create a "dummy" rom image, filled with hex E5
#
Set-Content -Value ([byte[]](0xE5) * (512KB - 64KB)) -Encoding byte -Path 'blank512KB.dat'
Set-Content -Value ([byte[]](0xE5) * (1MB - 64KB)) -Encoding byte -Path 'blank1024KB.dat'