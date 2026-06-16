# ZIP olustur + GitHub Release adimlari

## 1) Yeni ZIP olustur (PowerShell)

Proje klasorunde:

```powershell
cd C:\Users\yseze\Projects\desktop-pet

# EXE derle
dotnet publish DesktopPet.csproj -c Release -r win-x64 `
  --self-contained true `
  -p:PublishSingleFile=true `
  -p:IncludeNativeLibrariesForSelfExtract=true `
  -o dist\DesktopPet-win-x64

# ZIP yap (Assets klasoru EXE ile birlikte icinde olmali)
$zip = "dist\DesktopPet-v1.0-win-x64.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path "dist\DesktopPet-win-x64\*" -DestinationPath $zip -Force

Write-Host "Hazir: $zip"
```

Tek komutla (script):

```powershell
powershell -ExecutionPolicy Bypass -File tools\CreateReleaseZip.ps1
```

---

## 2) GitHub'a yukle — Yontem A (Web, en kolay)

1. Ac: https://github.com/YigitSezenn/desktop-pet/releases
2. **Draft a new release** (veya mevcut release'i **Edit**)
3. **Choose a tag:** `v1.0` (yeni surum icin `v1.1` yaz)
4. **Release title:** `Desktop Pet v1.0`
5. Aciklama yaz (ornek: "Tilki pet, 6 frame yurume, isim balonu")
6. **Attach binaries** → `dist\DesktopPet-v1.0-win-x64.zip` dosyasini surukle
7. **Publish release**

Arkadaslarin indirme linki:
`https://github.com/YigitSezenn/desktop-pet/releases/latest`

---

## 3) GitHub'a yukle — Yontem B (Terminal / gh)

Once [GitHub CLI](https://cli.github.com/) kurulu ve `gh auth login` yapilmis olmali.

```powershell
cd C:\Users\yseze\Projects\desktop-pet

# Yeni surum (ilk kez)
gh release create v1.0 `
  --repo YigitSezenn/desktop-pet `
  --title "Desktop Pet v1.0" `
  --notes "Piksel tilki masaustu pet. .NET gerekmez." `
  "dist\DesktopPet-v1.0-win-x64.zip"

# Mevcut surumu guncelle (ZIP degistiyse)
gh release upload v1.0 "dist\DesktopPet-v1.0-win-x64.zip" --clobber
```

---

## 4) Kod degisikligi de varsa (git push)

```powershell
git add .
git commit -m "Guncelleme aciklamasi"
git push origin main
```

---

## Onemli notlar

- ZIP icinde **mutlaka** su ikisi birlikte olmali:
  - `DesktopPet.exe`
  - `Assets\` klasoru
- `dist\` ve `.zip` dosyalari repoya gitmez (`.gitignore`'da)
- Surum numarasini her yeni release'te artir: `v1.0` → `v1.1` → `v1.2`
