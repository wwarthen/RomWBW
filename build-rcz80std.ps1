# build-rcz80std.ps1
# Builds the RCZ80 std configuration for RomWBW
# Generates rcz80std ROM files and disk images

$ErrorActionPreference = 'Stop'

Write-Host "Building RCZ80 std configuration..." -ForegroundColor Cyan

try {
    # Build HBIOS ROM
    Write-Host "`nBuilding HBIOS ROM..." -ForegroundColor Yellow
    Set-Location "Source/HBIOS"
    & cmd /c Build.cmd RCZ80 std rcz80std
    if ($LASTEXITCODE -ne 0) {
        Write-Host "HBIOS build failed!" -ForegroundColor Red
        exit 1
    }
    
    Set-Location "../.."
    
    # Build disk images
    Write-Host "`nBuilding disk images..." -ForegroundColor Yellow
    Set-Location "Source/Images"
    & cmd /c Build.cmd
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Disk image build failed!" -ForegroundColor Red
        exit 1
    }
    
    Set-Location "../.."
    
    # Display results
    Write-Host "`nBuild completed!" -ForegroundColor Green
    Write-Host "`nROM files in Binary/:" -ForegroundColor Cyan
    Get-ChildItem Binary/rcz80std.* -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  - $_" }
    
    Write-Host "`nhd1k disk images in Binary/:" -ForegroundColor Cyan
    Get-ChildItem Binary/hd1k_*.img -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  - $_" }
}
catch {
    Write-Host "`nBuild failed with error: $_" -ForegroundColor Red
    exit 1
}
