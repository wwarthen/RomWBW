# Process VGZ files: extract from ZIPs, uncompress, and rename to 8.3 notation

$ErrorActionPreference = "Stop"

# Function to intelligently convert a filename to 8.3 notation
function ConvertTo-8Dot3Name {
    param (
        [string]$OriginalName,
        [string[]]$ExistingNames
    )
    
    # Remove extension and clean the name
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($OriginalName)
    
    # Remove common noise words and clean up
    $baseName = $baseName -replace '\s*(VGM|vgm)\s*', ''
    $baseName = $baseName -replace '[_\-\s]+', ' '
    $baseName = $baseName.Trim()
    
    # Strategy: Extract meaningful parts
    # 1. Try to identify artists, song names, game names
    # 2. Use capitalized words (likely important)
    # 3. Use vowel removal if needed
    # 4. Add numeric suffix if collision
    
    $words = $baseName -split '\s+'
    $result = ""
    
    # Prioritize words by importance (capitalized, longer words first)
    $sortedWords = $words | Where-Object { $_.Length -gt 0 } | Sort-Object -Property @{
        Expression = { if ($_ -cmatch '^[A-Z]') { 0 } else { 1 } }
    }, @{
        Expression = { -$_.Length }
    }
    
    foreach ($word in $sortedWords) {
        $cleanWord = $word -replace '[^a-zA-Z0-9]', ''
        if ($cleanWord.Length -eq 0) { continue }
        
        $available = 8 - $result.Length
        if ($available -le 0) { break }
        
        if ($cleanWord.Length -le $available) {
            $result += $cleanWord
        } else {
            # Need to abbreviate this word
            # Remove vowels from the middle, keep consonants
            $abbreviated = $cleanWord[0]
            for ($i = 1; $i -lt $cleanWord.Length -and $abbreviated.Length -lt $available; $i++) {
                $char = $cleanWord[$i]
                if ($char -notmatch '[aeiouAEIOU]' -or $i -eq ($cleanWord.Length - 1)) {
                    $abbreviated += $char
                }
            }
            $result += $abbreviated.Substring(0, [Math]::Min($abbreviated.Length, $available))
            break
        }
    }
    
    # Ensure we have something
    if ($result.Length -eq 0) {
        $result = ($baseName -replace '[^a-zA-Z0-9]', '').Substring(0, [Math]::Min(8, $baseName.Length))
    }
    
    # Truncate to 8 characters
    $result = $result.Substring(0, [Math]::Min(8, $result.Length))
    
    # Handle collisions by adding numeric suffix
    $finalName = $result
    $counter = 1
    while ($ExistingNames -contains "$finalName.vgm") {
        $suffix = $counter.ToString()
        $maxBase = 8 - $suffix.Length
        $finalName = $result.Substring(0, [Math]::Min($maxBase, $result.Length)) + $suffix
        $counter++
    }
    
    return "$finalName.vgm"
}

Write-Host "Processing VGZ files..." -ForegroundColor Cyan

# Step 1: Extract VGZ files from ZIP archives
$zipFiles = Get-ChildItem -Path . -Filter "*.zip"
foreach ($zipFile in $zipFiles) {
    Write-Host "Extracting $($zipFile.Name)..." -ForegroundColor Yellow
    
    # Create temp directory for extraction
    $tempDir = Join-Path $env:TEMP "vgz_extract_$([guid]::NewGuid().ToString())"
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    
    try {
        # Extract ZIP
        Expand-Archive -Path $zipFile.FullName -DestinationPath $tempDir -Force
        
        # Find and move VGZ files to current directory
        $vgzFiles = Get-ChildItem -Path $tempDir -Filter "*.vgz" -Recurse
        foreach ($vgzFile in $vgzFiles) {
            $destPath = Join-Path (Get-Location) $vgzFile.Name
            Move-Item -Path $vgzFile.FullName -Destination $destPath -Force
            Write-Host "  Extracted: $($vgzFile.Name)" -ForegroundColor Green
        }
    } finally {
        # Clean up temp directory
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Delete the ZIP file
    Remove-Item -Path $zipFile.FullName -Force
    Write-Host "  Deleted: $($zipFile.Name)" -ForegroundColor DarkGray
}

# Step 2: Uncompress all VGZ files
$vgzFiles = Get-ChildItem -Path . -Filter "*.vgz"
$vgmFiles = @()

foreach ($vgzFile in $vgzFiles) {
    Write-Host "Uncompressing $($vgzFile.Name)..." -ForegroundColor Yellow
    
    $vgmName = [System.IO.Path]::ChangeExtension($vgzFile.Name, ".vgm")
    $vgmPath = Join-Path (Get-Location) $vgmName
    
    # Uncompress using .NET GZipStream
    try {
        $inputStream = [System.IO.File]::OpenRead($vgzFile.FullName)
        $outputStream = [System.IO.File]::Create($vgmPath)
        $gzipStream = New-Object System.IO.Compression.GZipStream($inputStream, [System.IO.Compression.CompressionMode]::Decompress)
        
        $gzipStream.CopyTo($outputStream)
        
        $gzipStream.Close()
        $outputStream.Close()
        $inputStream.Close()
        
        Write-Host "  Created: $vgmName" -ForegroundColor Green
        $vgmFiles += $vgmPath
    } catch {
        Write-Host "  Error uncompressing $($vgzFile.Name): $_" -ForegroundColor Red
        if (Test-Path $vgmPath) {
            Remove-Item $vgmPath -Force
        }
        continue
    }
    
    # Delete the original VGZ file
    Remove-Item -Path $vgzFile.FullName -Force
    Write-Host "  Deleted: $($vgzFile.Name)" -ForegroundColor DarkGray
}

# Step 3: Delete any non-VGM files that might have been extracted from ZIPs
# Define protected files that should never be deleted
$protectedFiles = @(
    "process-vgz.ps1",
    "cpmzip.ps1",
    "cpmzip.py",
    "*.txt",
    "*.md",
    "*.cmd"
)

# Keep track of files extracted from ZIPs
$extractedFiles = @()

# Step 1: Extract VGZ files from ZIP archives
$zipFiles = Get-ChildItem -Path . -Filter "*.zip"
foreach ($zipFile in $zipFiles) {
    Write-Host "Extracting $($zipFile.Name)..." -ForegroundColor Yellow
    
    # Create temp directory for extraction
    $tempDir = Join-Path $env:TEMP "vgz_extract_$([guid]::NewGuid().ToString())"
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    
    try {
        # Extract ZIP
        Expand-Archive -Path $zipFile.FullName -DestinationPath $tempDir -Force
        
        # Find and move VGZ files to current directory
        $vgzFiles = Get-ChildItem -Path $tempDir -Filter "*.vgz" -Recurse
        foreach ($vgzFile in $vgzFiles) {
            $destPath = Join-Path (Get-Location) $vgzFile.Name
            Move-Item -Path $vgzFile.FullName -Destination $destPath -Force
            Write-Host "  Extracted: $($vgzFile.Name)" -ForegroundColor Green
            $extractedFiles += $vgzFile.Name
        }
        
        # Find and move any other extracted files to mark them as from ZIP
        $otherExtracted = Get-ChildItem -Path $tempDir -File -Recurse
        foreach ($file in $otherExtracted) {
            if ($file.Extension -ne ".vgz") {
                $extractedFiles += $file.Name
            }
        }
        
    } finally {
        # Clean up temp directory
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Delete the ZIP file
    Remove-Item -Path $zipFile.FullName -Force
    Write-Host "  Deleted: $($zipFile.Name)" -ForegroundColor DarkGray
}

# Now delete non-VGM files but ONLY those that came from ZIPs
$allFiles = Get-ChildItem -Path . -File
foreach ($file in $allFiles) {
    # Check if this file should be protected
    $isProtected = $false
    foreach ($pattern in $protectedFiles) {
        if ($file.Name -like $pattern) {
            $isProtected = $true
            break
        }
    }
    
    # Only delete if:
    # 1. Not a VGM file
    # 2. Not in protected list
    # 3. Was extracted from a ZIP
    if ($file.Extension -ne ".vgm" -and -not $isProtected -and $extractedFiles -contains $file.Name) {
        Remove-Item -Path $file.FullName -Force
        Write-Host "Deleted extracted file: $($file.Name)" -ForegroundColor DarkGray
    }
}

# Step 3.5: Delete VGM files outside size range (5KB - 44KB)
Write-Host "`nFiltering VGM files by size..." -ForegroundColor Cyan
$vgmFiles = Get-ChildItem -Path . -Filter "*.vgm"
$minBytes = 5KB    # 5 * 1024
$maxBytes = 44KB   # 44 * 1024
foreach ($vgmFile in $vgmFiles) {
    $sizeBytes = $vgmFile.Length
    if ($sizeBytes -lt $minBytes -or $sizeBytes -gt $maxBytes) {
        $sizeKB = [Math]::Round($sizeBytes / 1KB, 2)
        Remove-Item -Path $vgmFile.FullName -Force
        Write-Host "Deleted $($vgmFile.Name) (size: $sizeKB KB)" -ForegroundColor DarkGray
    }
}

# Step 4: Rename VGM files to 8.3 notation
Write-Host "`nRenaming files to 8.3 notation..." -ForegroundColor Cyan

$vgmFiles = Get-ChildItem -Path . -Filter "*.vgm"
$newNames = @()
$renameMap = @{}

foreach ($vgmFile in $vgmFiles) {
    $new8Dot3Name = ConvertTo-8Dot3Name -OriginalName $vgmFile.Name -ExistingNames $newNames
    $newNames += $new8Dot3Name
    $renameMap[$vgmFile.FullName] = $new8Dot3Name
}

# Perform renames
foreach ($oldPath in $renameMap.Keys) {
    $newName = $renameMap[$oldPath]
    $newPath = Join-Path (Get-Location) $newName
    
    $oldName = Split-Path $oldPath -Leaf
    
    if ($oldName -ne $newName) {
        Rename-Item -Path $oldPath -NewName $newName -Force
        Write-Host "$oldName -> $newName" -ForegroundColor Green
    } else {
        Write-Host "$oldName (no change)" -ForegroundColor Gray
    }
}

Write-Host "`nProcessing complete!" -ForegroundColor Cyan
Write-Host "Total VGM files: $($newNames.Count)" -ForegroundColor Green
