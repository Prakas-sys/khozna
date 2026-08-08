Add-Type -AssemblyName System.Drawing

$originalPath = "d:\STARTUP\Khozna\KHOZNA.COM\assets\images\logo 2.png"
$backupPath = "d:\STARTUP\Khozna\KHOZNA.COM\assets\images\logo 2_original.png"

# Load the original backup image
$img = [System.Drawing.Image]::FromFile($backupPath)

# Setting target size: Canvas is 1024x1024
$canvasDim = 1024
# Logo size: Changed from 380 (too small) to 580 (perfect, balanced presentation at 57% of canvas size)
$logoDim = 580

$bmp = New-Object System.Drawing.Bitmap($canvasDim, $canvasDim)
$g = [System.Drawing.Graphics]::FromImage($bmp)

# Set high quality rendering options
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

# Clear with transparent background
$g.Clear([System.Drawing.Color]::Transparent)

# Calculate centered coordinates
$x = [int](($canvasDim - $logoDim) / 2)
$y = [int](($canvasDim - $logoDim) / 2)

# Draw the original image resized and centered
$g.DrawImage($img, $x, $y, $logoDim, $logoDim)

# Dispose graphics and original image to unlock files
$g.Dispose()
$img.Dispose()

# Save the new bitmap
$bmp.Save($originalPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

Write-Host "Resized padded image saved to $originalPath with dimension 1024 x 1024 (Logo size: $logoDim x $logoDim)"
