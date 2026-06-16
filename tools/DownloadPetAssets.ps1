# Harici pet asset paketlerini indirir / hazirlar.
# ToffeeCraft AnimalPack icin zip dosyasini manuel indirip ExternalSprites\toffeecraft\ altina koy.

$root = Split-Path $PSScriptRoot -Parent
$ErrorActionPreference = "Stop"

function Ensure-Dir([string]$Path) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Download-IfMissing {
    param([string]$Url, [string]$DestPath)

    if (Test-Path $DestPath) {
        Write-Host "Mevcut: $DestPath"
        return
    }

    Write-Host "Indiriliyor: $Url"
    Invoke-WebRequest -Uri $Url -OutFile $DestPath
}

Ensure-Dir (Join-Path $root "ExternalSprites\craftpix-street")
Ensure-Dir (Join-Path $root "ExternalSprites\oga")
Ensure-Dir (Join-Path $root "ExternalSprites\toffeecraft")

$streetZip = Join-Path $root "ExternalSprites\craftpix-street\street_animals.zip"
Download-IfMissing "https://opengameart.org/sites/default/files/street_animals.zip" $streetZip

$ogaFiles = @{
    "wolfsheet1.png" = "https://opengameart.org/sites/default/files/wolfsheet1.png"
    "lr_penguin2.png" = "https://opengameart.org/sites/default/files/lr_penguin2.png"
    "cat-1.0.zip" = "https://opengameart.org/sites/default/files/cat-1.0.zip"
    "shepard_dog.zip" = "https://opengameart.org/sites/default/files/dog.zip"
}

foreach ($entry in $ogaFiles.GetEnumerator()) {
    Download-IfMissing $entry.Value (Join-Path $root "ExternalSprites\oga\$($entry.Key)")
}

$catRework = Join-Path $root "ExternalSprites\oga\cat-rework\PNG\cat.png"
if (-not (Test-Path $catRework)) {
    $catZip = Join-Path $root "ExternalSprites\oga\cat-1.0.zip"
    if (Test-Path $catZip) {
        Expand-Archive -Path $catZip -DestinationPath (Join-Path $root "ExternalSprites\oga\cat-rework") -Force
    }
}

Write-Host ""
Write-Host "ToffeeCraft (istege bagli, daha iyi kopek animasyonlari):"
Write-Host "  1. https://toffeecraft.itch.io/animal-mega-pack adresinden AnimalPack.zip veya FreeAnimalPack.zip indir"
Write-Host "  2. Zip dosyasini su klasore koy: ExternalSprites\toffeecraft\"
Write-Host "  3. tools\ImportAllPets.ps1 calistir"
Write-Host ""
Write-Host "Craftpix Hunt Animals (tilki): ExternalSprites\craftpix-hunt-animals\ zaten mevcut olmali."
Write-Host ""
Write-Host "Sprite olusturmak icin:"
Write-Host "  powershell -ExecutionPolicy Bypass -File tools\ImportAllPets.ps1"
