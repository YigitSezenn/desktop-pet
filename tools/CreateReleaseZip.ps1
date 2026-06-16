# Yeni release ZIP olusturur
$root = Split-Path $PSScriptRoot -Parent
$outDir = Join-Path $root "dist\DesktopPet-win-x64"
$zip = Join-Path $root "dist\DesktopPet-v1.0-win-x64.zip"

Write-Host "Derleniyor..."
Push-Location $root
dotnet publish DesktopPet.csproj -c Release -r win-x64 `
  --self-contained true `
  -p:PublishSingleFile=true `
  -p:IncludeNativeLibrariesForSelfExtract=true `
  -o $outDir
if ($LASTEXITCODE -ne 0) { Pop-Location; exit 1 }

if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path "$outDir\*" -DestinationPath $zip -Force
Pop-Location

$size = [math]::Round((Get-Item $zip).Length / 1MB, 1)
Write-Host "ZIP hazir: $zip ($size MB)"
Write-Host ""
Write-Host "GitHub'a yuklemek icin:"
Write-Host "  gh release upload v1.0 `"$zip`" --clobber"
Write-Host "  veya Releases sayfasindan ZIP'i surukle-birak"
