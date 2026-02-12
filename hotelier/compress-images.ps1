# Image Compression Script
# Compresses JPEG images to reduce file size while maintaining good quality

$ErrorActionPreference = "Stop"

# Add System.Drawing assembly
Add-Type -AssemblyName System.Drawing

$imgPath = "img"
$backupPath = "img_backup"
$quality = 85  # JPEG quality (0-100, 85 is good balance)

# Create backup directory
if (Test-Path $backupPath) {
    Remove-Item $backupPath -Recurse -Force
}
New-Item -ItemType Directory -Path $backupPath | Out-Null

Write-Host "Backing up original images..." -ForegroundColor Yellow
Copy-Item -Path "$imgPath\*" -Destination $backupPath -Recurse -Force

Write-Host "`nCompressing images..." -ForegroundColor Green

$totalOriginalSize = 0
$totalCompressedSize = 0
$processed = 0

Get-ChildItem -Path $imgPath -Recurse -File -Include *.jpg,*.jpeg,*.JPG,*.JPEG | ForEach-Object {
    $originalFile = $_.FullName
    $originalSize = $_.Length
    $totalOriginalSize += $originalSize
    
    try {
        # Load the image
        $image = [System.Drawing.Image]::FromFile($originalFile)
        
        # Create encoder parameters
        $encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, $quality)
        
        # Save to temporary file first
        $tempFile = $originalFile + ".tmp"
        $image.Save($tempFile, $encoder, $encoderParams)
        
        # Dispose
        $image.Dispose()
        $encoderParams.Dispose()
        
        # Replace original with compressed version
        Remove-Item $originalFile -Force
        Move-Item $tempFile $originalFile -Force
        
        # Get new size
        $newSize = (Get-Item $originalFile).Length
        $totalCompressedSize += $newSize
        $saved = $originalSize - $newSize
        $percentSaved = [math]::Round(($saved / $originalSize) * 100, 1)
        
        $processed++
        Write-Host "[OK] $($_.Name) - $([math]::Round($originalSize/1MB, 2)) MB -> $([math]::Round($newSize/1MB, 2)) MB (saved $percentSaved%)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "[ERROR] Error processing $($_.Name): $_" -ForegroundColor Red
        # Clean up temp file if it exists
        $tempFile = $originalFile + ".tmp"
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "`n" -NoNewline
Write-Host "=" * 60 -ForegroundColor Green
Write-Host "Compression Complete!" -ForegroundColor Green
Write-Host "Processed: $processed images" -ForegroundColor White
Write-Host "Original total: $([math]::Round($totalOriginalSize/1MB, 2)) MB" -ForegroundColor White
Write-Host "Compressed total: $([math]::Round($totalCompressedSize/1MB, 2)) MB" -ForegroundColor White
Write-Host "Total saved: $([math]::Round(($totalOriginalSize - $totalCompressedSize)/1MB, 2)) MB ($([math]::Round((($totalOriginalSize - $totalCompressedSize) / $totalOriginalSize) * 100, 1))%)" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Green
Write-Host "`nOriginal images backed up to: $backupPath" -ForegroundColor Yellow

