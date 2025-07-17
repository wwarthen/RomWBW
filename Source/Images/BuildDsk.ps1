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
