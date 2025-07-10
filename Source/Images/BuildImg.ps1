param([string]$Image)

# If a PowerShell exception occurs, just stop the script immediately.
$ErrorAction = 'Stop'

$DefFile = $Image + ".def"

$ImgFile = "..\..\Binary\hd1k_" + $Image + ".img"




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

function CreateImageFile {
  param (
    [string]$Format = ""	# hd1k or hd512
  )

  $ImgFile = "..\..\Binary\" + $Format + "_" + $Image + ".img"
  
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
  cmd.exe /c copy /b $FileList $ImgFile
}

CreateImageFile "hd512"
CreateImageFile "hd1k"

exit 0
