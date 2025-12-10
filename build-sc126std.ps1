# build-sc126std.ps1
# Builds the SCZ180 sc126_std configuration for RomWBW
# Generates sc126std ROM files and disk images

$ErrorActionPreference = 'Stop'

Write-Host "Building SCZ180 sc126_std configuration..." -ForegroundColor Cyan

try {
    # Build HBIOS ROM
    Write-Host "`nBuilding HBIOS ROM..." -ForegroundColor Yellow
    Set-Location "Source/HBIOS"
    & cmd /c Build.cmd SCZ180 sc126_std sc126std
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
    ls Binary/sc126std.* 2>/dev/null | ForEach-Object { Write-Host "  - $_" }
    
    Write-Host "`nhd1k disk images in Binary/:" -ForegroundColor Cyan
    ls Binary/hd1k_*.img 2>/dev/null | ForEach-Object { Write-Host "  - $_" }
}
catch {
    Write-Host "`nBuild failed with error: $_" -ForegroundColor Red
    exit 1
}
