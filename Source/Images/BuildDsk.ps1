# This PowerShell script will build an aggregate hard disk
# image based on the parameter passed in.  The single
# input parameter is the name of the desired image.  E.g.,
# hd1k_combo.img will build a combo disk image (defined in combo.def)
# using the hd1k format.

param([string]$Disk)

# If a PowerShell exception occurs, just stop the script immediately.
$ErrorAction = 'Stop'

# $ImgFile = "..\..\Binary\hd1k_" + $Image + ".img"

$Format, $Def = $Disk.Split("_")

$DefFile = $Def + ".def"

$SliceList = @()

ForEach ($Line in Get-Content $DefFile)
{
  $Line = $Line.Trim()
  
  if (($Line.Length -eq 0) -or ($Line[0] -eq "#"))
  {
    continue    
  }
  
  $SliceList += $Line
}

$ImgFile = "..\..\Binary\" + $Disk + ".img"

$FileList = ""

"Generating $ImgFile using $DefFile..."

ForEach ($Slice in $SliceList)
{
  $File = "..\..\Binary\" + $Format + "_" + $Slice + ".img"
  
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

if ($Format -eq "hd1k")
{
  $FileList = "hd1k_prefix.dat+" + $FileList
}

$Cmd = "$env:ComSpec /c copy /b $FileList $ImgFile"
$Cmd
Invoke-Expression $Cmd

exit 0
