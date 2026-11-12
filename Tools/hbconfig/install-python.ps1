# install-python.ps1: downloads a private Python for hbconfig into Tools\python.
#
# Run by Config.cmd, the first time (after asking) or as "Config -install".
# Puts the official python.org embeddable Python and the windows-curses
# package into Tools\python. Nothing outside the RomWBW tree is touched:
# no system Python, no registry, no PATH change. Delete Tools\python to
# remove it again.
#
# Every download is checked against the SHA-256 below, the install stops
# if one does not match. To move to another version, change the four
# values in the block below (python.org keeps Windows binaries only up to
# 3.12.10 for the 3.12 series).
#
# AI: this script was written with Claude, an AI (LLM) by Anthropic. Claude
# wrote the code; Willy De la Court directed it, reviewed every change and
# tested it. It belongs to hbconfig, see Tools\hbconfig\ReadMe.txt.

$PyUrl     = 'https://www.python.org/ftp/python/3.12.10/python-3.12.10-embed-amd64.zip'
$PySha     = '4acbed6dd1c744b0376e3b1cf57ce906f9dc9e95e68824584c8099a63025a3c3'
$CursesUrl = 'https://files.pythonhosted.org/packages/8b/ee/8c5da36191524856fb2c675f8cae99211ccf77bcd4e4a9010477e08000ac/windows_curses-2.4.2-cp312-cp312-win_amd64.whl'
$CursesSha = 'df782859176f9e8142618e4966d6cee7a53a8b1c819faeb6e606a60fa4f8972a'

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Fail($msg) {
    Write-Host "hbconfig: $msg"
    exit 1
}

# The embeddable Python and the curses wheel are 64-bit only.
if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64' -and $env:PROCESSOR_ARCHITEW6432 -ne 'AMD64') {
    Fail 'the private Python is 64-bit only, and this Windows is not 64-bit x86.'
}

$Tools = Split-Path -Parent $PSScriptRoot
$Dest  = Join-Path $Tools 'python'
$Stage = Join-Path $Tools 'python.new'
$Temp  = Join-Path $env:TEMP ('hbconfig-' + [guid]::NewGuid().ToString('N'))

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    New-Item -ItemType Directory -Path $Temp | Out-Null
    if (Test-Path $Stage) { Remove-Item -Recurse -Force $Stage }

    # A wheel is a zip file, Expand-Archive only takes the .zip name.
    $files = @(
        @{ Url = $PyUrl;     Sha = $PySha;     Name = 'python.zip' },
        @{ Url = $CursesUrl; Sha = $CursesSha; Name = 'curses.zip' }
    )
    foreach ($f in $files) {
        $path = Join-Path $Temp $f.Name
        Write-Host "hbconfig: downloading $($f.Url)"
        Invoke-WebRequest -UseBasicParsing -Uri $f.Url -OutFile $path
        $got = (Get-FileHash -Algorithm SHA256 -Path $path).Hash
        if ($got -ine $f.Sha) {
            Fail "checksum of $($f.Name) does not match, nothing installed.`n  expected $($f.Sha)`n  got      $got"
        }
    }

    Expand-Archive -Path (Join-Path $Temp 'python.zip') -DestinationPath $Stage
    $site = Join-Path $Stage 'Lib\site-packages'
    New-Item -ItemType Directory -Path $site -Force | Out-Null
    Expand-Archive -Path (Join-Path $Temp 'curses.zip') -DestinationPath $site

    # The embeddable Python ignores the script's folder and PYTHONPATH. Its
    # python3NN._pth file is the whole search path, so list what hbconfig
    # needs: the standard library zip, site-packages and the tool's folder.
    $pth = Get-ChildItem -Path $Stage -Filter 'python3*._pth' | Select-Object -First 1
    if (-not $pth) { Fail 'no python3NN._pth file in the Python download.' }
    $zip = ($pth.BaseName -replace '\._pth$', '') + '.zip'
    $lines = @($zip, '.', 'Lib\site-packages', '..\hbconfig')
    [IO.File]::WriteAllText($pth.FullName, (($lines -join "`r`n") + "`r`n"))

    # Prove it works before it replaces anything.
    & (Join-Path $Stage 'python.exe') -c 'import curses, sys; sys.exit(0)'
    if ($LASTEXITCODE -ne 0) { Fail 'the new Python cannot import curses, nothing installed.' }

    if (Test-Path $Dest) { Remove-Item -Recurse -Force $Dest }
    Move-Item -Path $Stage -Destination $Dest
    Write-Host "hbconfig: installed in $Dest"
}
catch {
    Fail "install failed: $($_.Exception.Message)"
}
finally {
    if (Test-Path $Temp)  { Remove-Item -Recurse -Force $Temp }
    if (Test-Path $Stage) { Remove-Item -Recurse -Force $Stage }
}
