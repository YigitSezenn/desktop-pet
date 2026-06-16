Add-Type -AssemblyName System.Drawing

$foxDir = "C:\Users\yseze\Projects\desktop-pet\ExternalSprites\craftpix-hunt-animals\PNG\With_Shadow\Fox"
$out    = "C:\Users\yseze\Projects\desktop-pet\Assets"
$F      = 32

New-Item -ItemType Directory -Force -Path $out | Out-Null

function Crop-Frame {
    param(
        [System.Drawing.Bitmap]$Sheet,
        [int]$Col,
        [int]$Row,
        [string]$DestPath
    )

    $x = $Col * $F
    $y = $Row * $F
    $rect = [System.Drawing.Rectangle]::new($x, $y, $F, $F)
    $crop = $Sheet.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $crop.Save($DestPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $crop.Dispose()
    Write-Host "Saved $DestPath (col=$Col row=$Row)"
}

$walk  = [System.Drawing.Bitmap]::FromFile("$foxDir\Fox_walk_with_shadow.png")
$run   = [System.Drawing.Bitmap]::FromFile("$foxDir\Fox_Run_with_shadow.png")
$death = [System.Drawing.Bitmap]::FromFile("$foxDir\Fox_Death_with_shadow.png")

# Row 2 = saga yurume (6 frame: col 0-5)
Crop-Frame $walk 0 2 "$out\pet_idle.png"
for ($i = 0; $i -lt 6; $i++) {
    Crop-Frame $walk $i 2 "$out\pet_walk_$($i+1).png"
}

# Ziplama: run sheet 3 frame
Crop-Frame $run 0 2 "$out\pet_jump.png"

# Uyku: death sheet
Crop-Frame $death 0 2 "$out\pet_sleep_1.png"
Crop-Frame $death 1 2 "$out\pet_sleep_2.png"

$walk.Dispose()
$run.Dispose()
$death.Dispose()

Get-ChildItem $out -Filter "_*" | Remove-Item -Force -ErrorAction SilentlyContinue
Write-Host "Done - 6 walk frames imported."
