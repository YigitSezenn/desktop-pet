# Desktop Pet 🦊

Windows masaüstünde gezen piksel tilki. Sol alt köşede sağa-sola yürür, zıplar, uyur ve ara sıra konuşur.

![.NET 8](https://img.shields.io/badge/.NET-8.0-purple)
![Windows](https://img.shields.io/badge/platform-Windows-blue)

## Özellikler

- Şeffaf, çerçevesiz pencere — masaüstünde pet gibi durur
- **Yürüme** (6 frame), **zıplama**, **uyuma** animasyonları
- Sadece **sağ–sol** hareket (sol alt bölge)
- **İsim balonu** — çift tık veya sağ tık → İsim Değiştir
- **Konuşma balonu** — rastgele kısa mesajlar
- **Sürükle-bırak** ile taşıma
- **Sistem tepsisi** ikonu (gizle / göster)
- **Windows ile başlat** (açılışta otomatik)

## Gereksinimler

- Windows 10/11 (64-bit)
- [.NET 8 SDK](https://dotnet.microsoft.com/download) (geliştirme için)

## Çalıştırma (geliştirme)

```powershell
git clone https://github.com/YigitSezenn/desktop-pet.git
cd desktop-pet
dotnet run
```

## EXE oluşturma (arkadaşlarına göndermek için)

```powershell
dotnet publish -c Release -r win-x64 --self-contained true `
  -p:PublishSingleFile=true `
  -o dist\DesktopPet-win-x64
```

`dist\DesktopPet-win-x64` klasörünü ZIP'leyip gönder. **Assets** klasörü EXE ile aynı yerde olmalı.

## Kullanım

| Eylem | Ne yapar |
|--------|----------|
| Çift tık | İsim değiştir |
| Sol tık + sürükle | Pet'i taşı |
| Sağ tık | Menü (gizle, isim, Windows ile başlat, kapat) |
| Tepsi ikonu çift tık | Gizliyse geri getir |

## Sprite'lar

Pet görselleri Craftpix **Fox** paketinden türetilmiştir (`Assets/pet_*.png`).

Kendi sprite'larını kullanmak için `Assets/` içine aynı isimlerle PNG koy:

- `pet_idle.png`
- `pet_walk_1.png` … `pet_walk_6.png`
- `pet_jump.png`
- `pet_sleep_1.png`, `pet_sleep_2.png`

Craftpix paketinden yeniden import:

```powershell
powershell -ExecutionPolicy Bypass -File tools\ImportCraftpixFox.ps1
```

## Ayarlar

`%AppData%\DesktopPet\settings.json`

```json
{
  "PetName": "Mochi",
  "StartWithWindows": true
}
```

## Proje yapısı

```
desktop-pet/
├── Assets/           # Sprite PNG'leri
├── Services/         # Animasyon, tepsi, ayarlar, startup
├── Views/            # İsim dialog penceresi
├── tools/            # Sprite import scriptleri
├── MainWindow.xaml   # UI
└── DesktopPet.csproj
```

## Lisans

Kaynak kod bu repo için serbest kullanım içindir. Craftpix sprite paketi kendi lisansına tabidir; dağıtırken kendi görsellerinizi kullanın veya Craftpix lisansına uyun.
