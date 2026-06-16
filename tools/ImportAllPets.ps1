Add-Type -AssemblyName System.Drawing

$root      = Split-Path $PSScriptRoot -Parent
$craftpix  = Join-Path $root "ExternalSprites\craftpix-hunt-animals\PNG\With_Shadow"
$assets    = Join-Path $root "Assets"
$petOutputSize = 32

function New-Dir([string]$Path) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Crop-Frame {
    param(
        [System.Drawing.Bitmap]$Sheet,
        [int]$Col,
        [int]$Row,
        [int]$Size,
        [string]$DestPath
    )

    $x = $Col * $Size
    $y = $Row * $Size
    $rect = [System.Drawing.Rectangle]::new($x, $y, $Size, $Size)
    $crop = $Sheet.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $crop.Save($DestPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $crop.Dispose()
}

function Resize-Nearest {
    param(
        [System.Drawing.Bitmap]$Source,
        [int]$TargetSize
    )

    $dest = New-Object System.Drawing.Bitmap $TargetSize, $TargetSize, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt $TargetSize; $y++) {
        for ($x = 0; $x -lt $TargetSize; $x++) {
            $sx = [Math]::Floor($x * $Source.Width / $TargetSize)
            $sy = [Math]::Floor($y * $Source.Height / $TargetSize)
            $dest.SetPixel($x, $y, $Source.GetPixel($sx, $sy))
        }
    }
    return $dest
}

function Save-Crop {
    param(
        [System.Drawing.Bitmap]$Sheet,
        [int]$Col,
        [int]$Row,
        [int]$SourceSize,
        [string]$DestPath
    )

    $x = $Col * $SourceSize
    $y = $Row * $SourceSize
    $rect = [System.Drawing.Rectangle]::new($x, $y, $SourceSize, $SourceSize)
    $crop = $Sheet.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    if ($SourceSize -ne $petOutputSize) {
        $resized = Resize-Nearest $crop $petOutputSize
        $crop.Dispose()
        $crop = $resized
    }
    $crop.Save($DestPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $crop.Dispose()
}

function Export-PetSet {
    param(
        [string]$OutDir,
        [System.Drawing.Bitmap]$IdleSheet,
        [int]$IdleCol,
        [int]$IdleRow,
        [System.Drawing.Bitmap]$WalkSheet,
        [int[]]$WalkCols,
        [int]$WalkRow,
        [System.Drawing.Bitmap]$JumpSheet,
        [int]$JumpCol,
        [int]$JumpRow,
        [System.Drawing.Bitmap]$SleepSheet,
        [int[]]$SleepCols,
        [int]$SleepRow,
        [int]$SourceSize = 32
    )

    New-Dir $OutDir
    Save-Crop $IdleSheet $IdleCol $IdleRow $SourceSize (Join-Path $OutDir "pet_idle.png")
    Save-Crop $JumpSheet $JumpCol $JumpRow $SourceSize (Join-Path $OutDir "pet_jump.png")

    for ($i = 0; $i -lt $WalkCols.Count; $i++) {
        Save-Crop $WalkSheet $WalkCols[$i] $WalkRow $SourceSize (Join-Path $OutDir "pet_walk_$($i + 1).png")
    }

    Save-Crop $SleepSheet $SleepCols[0] $SleepRow $SourceSize (Join-Path $OutDir "pet_sleep_1.png")
    Save-Crop $SleepSheet $SleepCols[1] $SleepRow $SourceSize (Join-Path $OutDir "pet_sleep_2.png")
}

function Import-CraftpixAnimal {
    param(
        [string]$FolderName,
        [string]$Prefix,
        [string]$PetId
    )

    $dir = Join-Path $craftpix $FolderName
    $walkName  = Get-ChildItem $dir -Filter "*walk*shadow*.png" | Select-Object -First 1 -ExpandProperty FullName
    $runName   = Get-ChildItem $dir -Filter "*run*shadow*.png" | Select-Object -First 1 -ExpandProperty FullName
    $deathName = Get-ChildItem $dir -Filter "*death*shadow*.png" | Select-Object -First 1 -ExpandProperty FullName

    if (-not $walkName -or -not $runName -or -not $deathName) {
        throw "Craftpix dosyalari bulunamadi: $FolderName"
    }

    $walk  = [System.Drawing.Bitmap]::FromFile($walkName)
    $run   = [System.Drawing.Bitmap]::FromFile($runName)
    $death = [System.Drawing.Bitmap]::FromFile($deathName)

    $out = Join-Path $assets $PetId
    Export-PetSet -OutDir $out `
        -IdleSheet $walk -IdleCol 0 -IdleRow 2 `
        -WalkSheet $walk -WalkCols @(0, 1, 2, 3, 4, 5) -WalkRow 2 `
        -JumpSheet $run -JumpCol 0 -JumpRow 2 `
        -SleepSheet $death -SleepCols @(0, 1) -SleepRow 2

    $walk.Dispose()
    $run.Dispose()
    $death.Dispose()
    Write-Host "Imported craftpix $PetId -> $out"
}

function Import-LpcSheetAnimal {
    param(
        [string]$SheetPath,
        [string]$PetId,
        [int]$SourceSize,
        [int]$IdleCol,
        [int]$IdleRow,
        [int[]]$WalkCols,
        [int]$WalkRow,
        [int]$JumpCol,
        [int]$JumpRow,
        [int[]]$SleepCols,
        [int]$SleepRow,
        [switch]$Flip,
        [switch]$UseFit
    )

    $sheet = [System.Drawing.Bitmap]::FromFile($SheetPath)
    $out = Join-Path $assets $PetId
    New-Dir $out

    function Export-LpcFrame {
        param([int]$Col, [int]$Row, [string]$DestPath)

        $x = $Col * $SourceSize
        $y = $Row * $SourceSize
        $rect = [System.Drawing.Rectangle]::new($x, $y, $SourceSize, $SourceSize)
        $crop = $sheet.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        if ($UseFit) {
            Save-PetFrame $crop $DestPath -Flip:$Flip
        }
        else {
            if ($SourceSize -ne $petOutputSize) {
                $resized = Resize-Nearest $crop $petOutputSize
                $crop.Dispose()
                $crop = $resized
            }
            if ($Flip) {
                $flipped = Flip-Horizontal $crop
                $crop.Dispose()
                $crop = $flipped
            }
            $crop.Save($DestPath, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        $crop.Dispose()
    }

    Export-LpcFrame $IdleCol $IdleRow (Join-Path $out "pet_idle.png")
    Export-LpcFrame $JumpCol $JumpRow (Join-Path $out "pet_jump.png")
    for ($i = 0; $i -lt $WalkCols.Count; $i++) {
        Export-LpcFrame $WalkCols[$i] $WalkRow (Join-Path $out "pet_walk_$($i + 1).png")
    }
    Export-LpcFrame $SleepCols[0] $SleepRow (Join-Path $out "pet_sleep_1.png")
    Export-LpcFrame $SleepCols[1] $SleepRow (Join-Path $out "pet_sleep_2.png")

    $sheet.Dispose()
    Write-Host "Imported LPC/OGA $PetId -> $out"
}

function Import-LegendsPenguin {
    param([string]$SheetPath)

    $sheet = [System.Drawing.Bitmap]::FromFile($SheetPath)
    $cellSize = $sheet.Height
    $frameCount = [Math]::Floor($sheet.Width / $cellSize)
    $out = Join-Path $assets "penguin"
    New-Dir $out

    function Export-PenguinFrame {
        param([int]$Index, [string]$DestPath)

        $col = [Math]::Min($Index, $frameCount - 1)
        $rect = [System.Drawing.Rectangle]::new($col * $cellSize, 0, $cellSize, $cellSize)
        $crop = $sheet.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        Save-PetFrame $crop $DestPath -Flip -ContentScale 0.72
        $crop.Dispose()
    }

    Export-PenguinFrame 0 (Join-Path $out "pet_idle.png")
    Export-PenguinFrame 3 (Join-Path $out "pet_jump.png")
    @(0, 1, 2, 3, 1, 2) | ForEach-Object -Begin { $i = 1 } -Process {
        Export-PenguinFrame $_ (Join-Path $out "pet_walk_$i.png")
        $i++
    }
    Export-PenguinFrame 0 (Join-Path $out "pet_sleep_1.png")
    Export-PenguinFrame 2 (Join-Path $out "pet_sleep_2.png")

    $sheet.Dispose()
    Write-Host "Imported Legends penguin -> $out"
}

function Import-WolfCub {
    param([string]$SheetPath)

    # wolf cub.png: 8x 32px kare, saga bakan yavru kurt (OGA, CC0)
    $sheet = [System.Drawing.Bitmap]::FromFile($SheetPath)
    $out = Join-Path $assets "wolf"
    $size = 32
    New-Dir $out

    function Export-CubFrame {
        param([int]$Col, [string]$DestPath)

        $rect = [System.Drawing.Rectangle]::new($Col * $size, 0, $size, $size)
        $crop = $sheet.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        Save-PetFrame $crop $DestPath -Flip -ContentScale 0.62
        $crop.Dispose()
    }

    Export-CubFrame 0 (Join-Path $out "pet_idle.png")
    for ($i = 0; $i -lt 6; $i++) {
        Export-CubFrame $i (Join-Path $out "pet_walk_$($i + 1).png")
    }
    Export-CubFrame 6 (Join-Path $out "pet_jump.png")
    Export-CubFrame 7 (Join-Path $out "pet_sleep_1.png")
    Export-CubFrame 7 (Join-Path $out "pet_sleep_2.png")

    $sheet.Dispose()
    Write-Host "Imported wolf cub -> $out"
}

function Import-WolfSide {
    param([string]$SheetPath)

    # wolfsheet1.png: 32px hucreler; yan profil yurume satiri 4, sutunlar 11-16 (saga bakar -> sola cevir)
    $sheet = [System.Drawing.Bitmap]::FromFile($SheetPath)
    $out = Join-Path $assets "wolf"
    $size = 32
    New-Dir $out

    function Export-WolfFrame {
        param([int]$Col, [int]$Row, [string]$DestPath)

        $rect = [System.Drawing.Rectangle]::new($Col * $size, $Row * $size, $size, $size)
        $crop = $sheet.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        Save-PetFrame $crop $DestPath -Flip -ContentScale 0.72
        $crop.Dispose()
    }

    Export-WolfFrame 11 4 (Join-Path $out "pet_idle.png")
    for ($i = 0; $i -lt 6; $i++) {
        Export-WolfFrame (11 + $i) 4 (Join-Path $out "pet_walk_$($i + 1).png")
    }
    Export-WolfFrame 11 6 (Join-Path $out "pet_jump.png")
    Export-WolfFrame 11 4 (Join-Path $out "pet_sleep_1.png")
    Export-WolfFrame 12 4 (Join-Path $out "pet_sleep_2.png")

    $sheet.Dispose()
    Write-Host "Imported wolf side-view -> $out"
}

function Flip-Horizontal {
    param([System.Drawing.Bitmap]$Source)

    $flipped = New-Object System.Drawing.Bitmap $Source.Width, $Source.Height, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt $Source.Height; $y++) {
        for ($x = 0; $x -lt $Source.Width; $x++) {
            $flipped.SetPixel($Source.Width - 1 - $x, $y, $Source.GetPixel($x, $y))
        }
    }
    return $flipped
}

function Fit-ToPetFrame {
    param(
        [System.Drawing.Bitmap]$Source,
        [switch]$Flip,
        [double]$ContentScale = 1.0
    )

    $src = $Source
    if ($Flip) {
        $src = Flip-Horizontal $Source
    }

    $dest = New-Object System.Drawing.Bitmap $petOutputSize, $petOutputSize, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $scale = [Math]::Min($petOutputSize / $src.Width, $petOutputSize / $src.Height) * $ContentScale
    $drawW = [Math]::Max(1, [int][Math]::Round($src.Width * $scale))
    $drawH = [Math]::Max(1, [int][Math]::Round($src.Height * $scale))
    $offsetX = [int](($petOutputSize - $drawW) / 2)
    $offsetY = $petOutputSize - $drawH

    for ($y = 0; $y -lt $petOutputSize; $y++) {
        for ($x = 0; $x -lt $petOutputSize; $x++) {
            $dest.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
        }
    }

    for ($y = 0; $y -lt $drawH; $y++) {
        for ($x = 0; $x -lt $drawW; $x++) {
            $sx = [Math]::Min($src.Width - 1, [Math]::Floor(($x + 0.5) / $scale))
            $sy = [Math]::Min($src.Height - 1, [Math]::Floor(($y + 0.5) / $scale))
            $dest.SetPixel($offsetX + $x, $offsetY + $y, $src.GetPixel($sx, $sy))
        }
    }

    if ($Flip -and $src -ne $Source) { $src.Dispose() }
    return $dest
}

function Save-PetFrame {
    param(
        [System.Drawing.Bitmap]$Frame,
        [string]$DestPath,
        [switch]$Flip,
        [double]$ContentScale = 1.0
    )

    $fitted = Fit-ToPetFrame $Frame -Flip:$Flip -ContentScale $ContentScale
    $fitted.Save($DestPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $fitted.Dispose()
}

function Get-StripFrameCount {
    param(
        [System.Drawing.Bitmap]$Sheet,
        [int]$FrameSize
    )

    if ($Sheet.Height -lt $FrameSize) { return 0 }
    return [Math]::Floor($Sheet.Width / $FrameSize)
}

function Import-CraftpixStreetAnimal {
    param(
        [string]$FolderPath,
        [string]$PetId,
        [switch]$Flip
    )

    $idlePath  = Join-Path $FolderPath "Idle.png"
    $walkPath  = Join-Path $FolderPath "Walk.png"
    $jumpPath  = Join-Path $FolderPath "Attack.png"
    $sleepPath = Join-Path $FolderPath "Death.png"

    if (-not (Test-Path $walkPath)) {
        throw "Craftpix Street dosyalari bulunamadi: $FolderPath"
    }
    if (-not (Test-Path $jumpPath)) {
        $jumpPath = Join-Path $FolderPath "Hurt.png"
    }

    $sourceFrameSize = 48
    if ((Get-Item $walkPath).Length -gt 0) {
        $probe = [System.Drawing.Bitmap]::FromFile($walkPath)
        if ($probe.Height -eq 32) { $sourceFrameSize = 32 }
        $probe.Dispose()
    }

    $idle  = if (Test-Path $idlePath)  { [System.Drawing.Bitmap]::FromFile($idlePath) }  else { $null }
    $walk  = [System.Drawing.Bitmap]::FromFile($walkPath)
    $jump  = if (Test-Path $jumpPath)  { [System.Drawing.Bitmap]::FromFile($jumpPath) }  else { $null }
    $sleep = if (Test-Path $sleepPath) { [System.Drawing.Bitmap]::FromFile($sleepPath) } else { $null }

    $out = Join-Path $assets $PetId
    New-Dir $out

    $walkCount = Get-StripFrameCount $walk $sourceFrameSize
    $walkCols = 0..([Math]::Min(5, $walkCount - 1))

    $idleCrop = if ($idle) {
        $rect = [System.Drawing.Rectangle]::new(0, 0, $sourceFrameSize, $sourceFrameSize)
        $idle.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    } else {
        $rect = [System.Drawing.Rectangle]::new(0, 0, $sourceFrameSize, $sourceFrameSize)
        $walk.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    }
    Save-PetFrame $idleCrop (Join-Path $out "pet_idle.png") -Flip:$Flip
    $idleCrop.Dispose()

    for ($i = 0; $i -lt $walkCols.Count; $i++) {
        $rect = [System.Drawing.Rectangle]::new($walkCols[$i] * $sourceFrameSize, 0, $sourceFrameSize, $sourceFrameSize)
        $crop = $walk.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        Save-PetFrame $crop (Join-Path $out "pet_walk_$($i + 1).png") -Flip:$Flip
        $crop.Dispose()
    }

    $jumpCrop = if ($jump) {
        $rect = [System.Drawing.Rectangle]::new(0, 0, $sourceFrameSize, $sourceFrameSize)
        $jump.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    } else {
        $rect = [System.Drawing.Rectangle]::new(0, 0, $sourceFrameSize, $sourceFrameSize)
        $walk.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    }
    Save-PetFrame $jumpCrop (Join-Path $out "pet_jump.png") -Flip:$Flip
    $jumpCrop.Dispose()

    if ($sleep) {
        for ($i = 0; $i -lt 2; $i++) {
            $col = [Math]::Min($i, (Get-StripFrameCount $sleep $sourceFrameSize) - 1)
            $rect = [System.Drawing.Rectangle]::new($col * $sourceFrameSize, 0, $sourceFrameSize, $sourceFrameSize)
            $crop = $sleep.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            Save-PetFrame $crop (Join-Path $out "pet_sleep_$($i + 1).png") -Flip:$Flip
            $crop.Dispose()
        }
        $sleep.Dispose()
    }

    if ($idle) { $idle.Dispose() }
    $walk.Dispose()
    if ($jump) { $jump.Dispose() }
    Write-Host "Imported Craftpix Street $PetId -> $out"
}

function Ensure-CraftpixStreetAssets {
    $streetRoot = Join-Path $root "ExternalSprites\craftpix-street"
    $zipPath    = Join-Path $streetRoot "street_animals.zip"
    $extractDir = Join-Path $streetRoot "extracted"

    if (-not (Test-Path (Join-Path $extractDir "1 Dog\Walk.png"))) {
        New-Item -ItemType Directory -Force -Path $streetRoot | Out-Null
        if (-not (Test-Path $zipPath)) {
            Write-Host "Downloading Craftpix Street Animals from OpenGameArt..."
            Invoke-WebRequest -Uri "https://opengameart.org/sites/default/files/street_animals.zip" -OutFile $zipPath
        }
        Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
    }

    return $extractDir
}

function Expand-ToffeeCraftArchives {
    param([string]$ToffeeRoot)

    if (-not (Test-Path $ToffeeRoot)) { return }

    Get-ChildItem $ToffeeRoot -Filter "*.zip" | ForEach-Object {
        $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
        if ($bytes.Length -lt 4 -or $bytes[0] -ne 0x50 -or $bytes[1] -ne 0x4B) {
            Write-Warning "Atlaniyor (gecerli zip degil): $($_.Name)"
            return
        }
        $target = Join-Path $ToffeeRoot ($_.BaseName)
        if (-not (Test-Path $target)) {
            Expand-Archive -Path $_.FullName -DestinationPath $target -Force
            Write-Host "Extracted ToffeeCraft $($_.Name)"
        }
    }
}

function Find-ToffeeCraftFolder {
    param(
        [string]$SearchRoot,
        [string[]]$NamePatterns
    )

    if (-not (Test-Path $SearchRoot)) { return $null }

    $folders = Get-ChildItem $SearchRoot -Recurse -Directory -ErrorAction SilentlyContinue
    foreach ($pattern in $NamePatterns) {
        $match = $folders | Where-Object { $_.Name -like $pattern } | Select-Object -First 1
        if ($match -and (Test-Path (Join-Path $match.FullName "Walk.png"))) {
            return $match.FullName
        }
    }
    return $null
}

function Import-ToffeeCraftAnimal {
    param(
        [string]$SearchRoot,
        [string]$PetId,
        [string[]]$FolderPatterns,
        [switch]$Flip
    )

    $folder = Find-ToffeeCraftFolder $SearchRoot $FolderPatterns
    if (-not $folder) { return $false }

    $walkPath = Join-Path $folder "Walk.png"
    $probe = [System.Drawing.Bitmap]::FromFile($walkPath)
    $sourceSize = if ($probe.Height -ge 64 -and $probe.Width % 64 -eq 0) { 64 } elseif ($probe.Height -eq 32) { 32 } else { $probe.Height }
    $probe.Dispose()

    $idlePath  = @("Idle.png", "Idle2.png") | ForEach-Object { Join-Path $folder $_ } | Where-Object { Test-Path $_ } | Select-Object -First 1
    $jumpPath  = @("Jump.png", "Run.png", "Attack.png") | ForEach-Object { Join-Path $folder $_ } | Where-Object { Test-Path $_ } | Select-Object -First 1
    $sleepPath = @("Sleep.png", "Die.png", "Die2.png", "Death.png") | ForEach-Object { Join-Path $folder $_ } | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $idlePath) { $idlePath = $walkPath }
    if (-not $jumpPath) { $jumpPath = $walkPath }
    if (-not $sleepPath) { $sleepPath = $walkPath }

    $out = Join-Path $assets $PetId
    New-Dir $out

    function Export-FromSheet {
        param([string]$Path, [int]$Col, [string]$Dest)

        $sheet = [System.Drawing.Bitmap]::FromFile($Path)
        $rect = [System.Drawing.Rectangle]::new($Col * $sourceSize, 0, $sourceSize, $sourceSize)
        $crop = $sheet.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $sheet.Dispose()
        Save-PetFrame $crop $Dest -Flip:$Flip
        $crop.Dispose()
    }

    Export-FromSheet $idlePath 0 (Join-Path $out "pet_idle.png")
    Export-FromSheet $jumpPath 0 (Join-Path $out "pet_jump.png")

    $walkSheet = [System.Drawing.Bitmap]::FromFile($walkPath)
    $walkCount = Get-StripFrameCount $walkSheet $sourceSize
    $walkSheet.Dispose()
    for ($i = 0; $i -lt [Math]::Min(6, $walkCount); $i++) {
        Export-FromSheet $walkPath $i (Join-Path $out "pet_walk_$($i + 1).png")
    }

    Export-FromSheet $sleepPath 0 (Join-Path $out "pet_sleep_1.png")
    $sleepSheet = [System.Drawing.Bitmap]::FromFile($sleepPath)
    $sleepCol = [Math]::Min(1, (Get-StripFrameCount $sleepSheet $sourceSize) - 1)
    $sleepSheet.Dispose()
    Export-FromSheet $sleepPath $sleepCol (Join-Path $out "pet_sleep_2.png")

    Write-Host "Imported ToffeeCraft $PetId -> $out"
    return $true
}

function Import-Dog {
    $toffeeRoot = Join-Path $root "ExternalSprites\toffeecraft"
    Expand-ToffeeCraftArchives $toffeeRoot

    if (Import-ToffeeCraftAnimal -SearchRoot $toffeeRoot -PetId "dog" -FolderPatterns @("*Dog*", "dog", "Dog")) {
        return
    }

    $streetDir = Ensure-CraftpixStreetAssets
    $dogFolder = Join-Path $streetDir "2 Dog 2"
    if (-not (Test-Path (Join-Path $dogFolder "Walk.png"))) {
        $dogFolder = Join-Path $streetDir "1 Dog"
    }
    Import-CraftpixStreetAnimal -FolderPath $dogFolder -PetId "dog" -Flip
    Write-Host "  (Craftpix Street Animals / OpenGameArt mirror)"
}

function New-DogSprites {
    param([string]$OutDir)

    New-Dir $OutDir

    $T  = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
    $Bo = [System.Drawing.Color]::FromArgb(255, 180, 120, 70)
    $Bs = [System.Drawing.Color]::FromArgb(255, 140, 85, 45)
    $Bh = [System.Drawing.Color]::FromArgb(255, 210, 155, 95)
    $Wh = [System.Drawing.Color]::FromArgb(255, 245, 235, 220)
    $Ey = [System.Drawing.Color]::FromArgb(255, 25, 25, 40)
    $Ns = [System.Drawing.Color]::FromArgb(255, 50, 35, 30)
    $Mo = [System.Drawing.Color]::FromArgb(255, 70, 40, 25)
    $Ear = [System.Drawing.Color]::FromArgb(255, 120, 70, 40)

    $map = @{
        '.' = $T; 'o' = $Bo; 's' = $Bs; 'h' = $Bh; 'w' = $Wh
        'e' = $Ey; 'n' = $Ns; 'm' = $Mo; 'r' = $Ear
    }

    function New-Bitmap([string[]]$Rows) {
        $bmp = New-Object System.Drawing.Bitmap 32, 32, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        for ($y = 0; $y -lt 32; $y++) {
            $row = if ($y -lt $Rows.Length) { $Rows[$y] } else { '.' * 32 }
            for ($x = 0; $x -lt 32; $x++) {
                $ch = if ($x -lt $row.Length) { $row[$x] } else { '.' }
                $color = if ($map.ContainsKey("$ch")) { $map["$ch"] } else { $T }
                $bmp.SetPixel($x, $y, $color)
            }
        }
        return $bmp
    }

    function Save-Bitmap([System.Drawing.Bitmap]$Bmp, [string]$Name) {
        $Bmp.Save((Join-Path $OutDir $Name), [System.Drawing.Imaging.ImageFormat]::Png)
        $Bmp.Dispose()
    }

    $idle = @(
        "................................",
        "....rr..............rr..........",
        "...rrrr............rrrr.........",
        "...rooo............oooo.........",
        "....oooooooooooooooooo..........",
        "...oooooooooooooooooooo.........",
        "..ooooooooooooooooooooos........",
        "..ooohhoooooooooohhoooos........",
        "..ooowwwwooooooowwwwoooos.......",
        "..oooweegwooooowgeewoooos.......",
        "..oooooooonoooooooooooos........",
        "...oooooommmooooooooooo.........",
        "...oooooooooooooooooooo.........",
        "....oooooooooooooooooo..........",
        ".....oooooooooooooooo...........",
        ".....soooooooooooooos...........",
        ".....sooo......oooos............",
        ".....ssos......soos.............",
        ".....ss.........ss..............",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................"
    )

    $walk1 = @(
        "................................",
        "....rr..............rr..........",
        "...rrrr............rrrr.........",
        "...rooo............oooo.........",
        "....oooooooooooooooooo..........",
        "...oooooooooooooooooooo.........",
        "..ooooooooooooooooooooos........",
        "..ooohhoooooooooohhoooos........",
        "..ooowwwwooooooowwwwoooos.......",
        "..oooweegwooooowgeewoooos.......",
        "..oooooooonoooooooooooos........",
        "...oooooommmooooooooooo.........",
        "...oooooooooooooooooooo.........",
        "....oooooooooooooooooo..........",
        ".....oooooooooooooooo...........",
        ".....soooooooooooooos...........",
        "....ssoos......oooss............",
        "...ssoos.......ooss.............",
        "...ss...........ss..............",
        "..ss............s...............",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................"
    )

    $walk2 = @(
        "................................",
        "....rr..............rr..........",
        "...rrrr............rrrr.........",
        "...rooo............oooo.........",
        "....oooooooooooooooooo..........",
        "...oooooooooooooooooooo.........",
        "..ooooooooooooooooooooos........",
        "..ooohhoooooooooohhoooos........",
        "..ooowwwwooooooowwwwoooos.......",
        "..oooweegwooooowgeewoooos.......",
        "..oooooooonoooooooooooos........",
        "...oooooommmooooooooooo.........",
        "...oooooooooooooooooooo.........",
        "....oooooooooooooooooo..........",
        ".....oooooooooooooooo...........",
        ".....soooooooooooooos...........",
        ".....ooss......ssoo.............",
        ".....oss........sso.............",
        ".....ss..........ss.............",
        "......s...........s.............",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................"
    )

    $jump = @(
        "................................",
        "....rr..............rr..........",
        "...rrrr............rrrr.........",
        "....oooooooooooooooooo..........",
        "...oooooooooooooooooooo.........",
        "..ooooooooooooooooooooos........",
        "..ooohhoooooooooohhoooos........",
        "..ooowwwwooooooowwwwoooos.......",
        "..oooweegwooooowgeewoooos.......",
        "..oooooooonoooooooooooos........",
        "...oooooooooooooooooooo.........",
        "....oooooooooooooooooo..........",
        ".....sooooooooooooooos..........",
        "....ss.ooooooooooooo.ss.........",
        "...ss..ooooooooooooo..ss........",
        "..ss...soos.....soos...ss.......",
        ".ss....sss.......sss....ss......",
        "ss......ss.......ss......ss.....",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................"
    )

    $sleep1 = @(
        "................................",
        "....rr..............rr..........",
        "...rrrr............rrrr.........",
        "....oooooooooooooooooo..........",
        "...oooooooooooooooooooo.........",
        "..ooowwwwooooooowwwwoooos.......",
        "..oooweemwooooowmeewoooos.......",
        "..oooooooonoooooooooooos........",
        "...oooooommmooooooooooo.........",
        "....soooooooooooooooos..........",
        "....soos.......sooos............",
        "....sss.........ssss............",
        "...............z................",
        "..............zz................",
        ".............zzz................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................"
    )

    $sleep2 = @(
        "................................",
        "....rr..............rr..........",
        "...rrrr............rrrr.........",
        "....oooooooooooooooooo..........",
        "...oooooooooooooooooooo.........",
        "..ooowwwwooooooowwwwoooos.......",
        "..oooweemwooooowmeewoooos.......",
        "..oooooooonoooooooooooos........",
        "...oooooommmooooooooooo.........",
        "....soooooooooooooooos..........",
        "....soos.......sooos............",
        "....sss.........ssss............",
        "..............z..................",
        ".............zz..................",
        "............zzz..................",
        "...........zzzz..................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................",
        "................................"
    )

    Save-Bitmap (New-Bitmap $idle) "pet_idle.png"
    Save-Bitmap (New-Bitmap $jump) "pet_jump.png"
    Save-Bitmap (New-Bitmap $walk1) "pet_walk_1.png"
    Save-Bitmap (New-Bitmap $walk2) "pet_walk_2.png"
    Save-Bitmap (New-Bitmap $walk1) "pet_walk_3.png"
    Save-Bitmap (New-Bitmap $walk2) "pet_walk_4.png"
    Save-Bitmap (New-Bitmap $walk1) "pet_walk_5.png"
    Save-Bitmap (New-Bitmap $walk2) "pet_walk_6.png"
    Save-Bitmap (New-Bitmap $sleep1) "pet_sleep_1.png"
    Save-Bitmap (New-Bitmap $sleep2) "pet_sleep_2.png"
    Write-Host "Generated procedural dog -> $OutDir"
}

New-Dir $assets

Import-CraftpixAnimal -FolderName "Fox" -Prefix "Fox" -PetId "fox"

$oga = Join-Path $root "ExternalSprites\oga"
$wolfCub = Join-Path $oga "wolf_cub.png"
if (Test-Path $wolfCub) {
    Import-WolfCub -SheetPath $wolfCub
}
else {
    Import-WolfSide -SheetPath (Join-Path $oga "wolfsheet1.png")
}

$streetDir = Ensure-CraftpixStreetAssets
Import-CraftpixStreetAnimal -FolderPath (Join-Path $streetDir "3 Cat") -PetId "cat" -Flip

$legendsPenguin = Join-Path $root "ExternalSprites\legends-penguin\penguin_test.png"
$penguinSheet = Join-Path $oga "lr_penguin2.png"
if (Test-Path $penguinSheet) {
  Import-LpcSheetAnimal `
    -SheetPath $penguinSheet `
    -PetId "penguin" `
    -SourceSize 32 `
    -IdleCol 0 -IdleRow 4 `
    -WalkCols @(0, 1, 2, 3, 4, 5) -WalkRow 4 `
    -JumpCol 1 -JumpRow 2 `
    -SleepCols @(0, 1) -SleepRow 6 `
    -Flip `
    -UseFit
}
elseif (Test-Path $legendsPenguin) {
    Import-LegendsPenguin -SheetPath $legendsPenguin
}
else {
    throw "Penguen sprite dosyasi bulunamadi."
}

Import-Dog

# Geriye uyumluluk: fox klasorunu kok Assets'e de kopyala
$foxDir = Join-Path $assets "fox"
Get-ChildItem $foxDir -Filter "pet_*.png" | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $assets $_.Name) -Force
}

Write-Host "Done - imported fox, wolf, cat, dog, penguin."
