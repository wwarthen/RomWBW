# This PowerShell script will build an aggregate hard disk image with three partitions:
#   - RomWBW partition with 16 slices (128MB)
#   - MSX-DOS FAT12 system partition (8MB)
#   - FAT16 data partition (100MB)
# The script must be invoked after all slice images are built.

# If a PowerShell exception occurs, just stop the script immediately.
$ErrorAction = 'Stop'

$DskFile = "..\..\Binary\msx_combo.dsk"

"Generating $DskFile..."

$FileList = ""

# Define the 16 slices
$SliceList = 'cpm22','zsdos','nzcom','cpm3','zpm3','wp','games','msx'
$SliceList += 'blank','blank','blank','blank','blank','blank','blank','blank'

ForEach ($Slice in $SliceList)
{
  $File = "..\..\Binary\hd1k_" + $Slice + ".img"
  
  if (!(Test-Path $File))
  {
    "Slice input file """ + $File + """ not found!!!"
    exit 1
  }
  
  if ($FileList.Length -gt 0)
  {
    $FileList += "+"
  }

  $FileList += $File
}

# Expand MBR and FAT partition images

Expand-Archive -Force -Path msximg.zip

# Populate FAT system partition

&"mtools" -c mcopy -i msximg\msx_sys.dsk -omv d_fat\*.* ::
&"mtools" -c mcopy -i msximg\msx_sys.dsk -omv ..\..\Binary\MSX_std.rom ::MSX-STD.ROM
&"mtools" -c mcopy -i msximg\msx_sys.dsk -omv ..\..\Binary\msx-ldr.com ::MSX-LDR.COM
&"mtools" -c mcopy -i msximg\msx_sys.dsk -omv ..\..\Binary\Apps\reboot.com ::REBOOT.COM

$FileList = "msximg\msx_mbr.dat +" + $FileList + "+ msximg\msx_sys.dsk + msximg\msx_data.dsk"

$Cmd = "$env:ComSpec /c copy /b $FileList $DskFile"
$Cmd
Invoke-Expression $Cmd

exit 0
