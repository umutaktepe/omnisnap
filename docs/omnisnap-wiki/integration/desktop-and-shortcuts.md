# Masaüstü Girişi ve KDE Kısayolları (Desktop & Shortcuts)

Omnisnap, KDE Plasma 6 masaüstü ortamına kusursuz entegre olacak şekilde bir `.desktop` dosyası ve standart kısayol şeması ile gelir.

## Masaüstü Dosyası: `omnisnap.desktop`
```ini
[Desktop Entry]
Name=Omnisnap
Comment=Modern Screenshot Tool for KDE Plasma 6
Exec=omnisnap region
Icon=camera-photo
Terminal=false
Type=Application
Categories=Utility;Graphics;
Keywords=screenshot;snip;capture;ocr;lens;
Actions=Region;FullScreen;Window;Settings;

[Desktop Action Region]
Name=Capture Rectangular Region
Exec=omnisnap region
Icon=select-rectangular

[Desktop Action FullScreen]
Name=Capture Entire Desktop
Exec=omnisnap full
Icon=view-fullscreen

[Desktop Action Window]
Name=Capture Active Window
Exec=omnisnap window
Icon=window

[Desktop Action Settings]
Name=Omnisnap Settings
Exec=omnisnap settings
Icon=preferences-system
```

Bu dosya `install.sh` tarafından `~/.local/share/applications/omnisnap.desktop` konumuna kopyalanır ve `Exec` yolları kullanıcının yerel ikili yoluna (`~/.local/bin/omnisnap`) göre otomatik olarak güncellenir ([[installation-and-packaging]]).

## KDE Plasma 6 Kısayol Yapılandırması
KDE Plasma 6, `.desktop` dosyasındaki eylemleri (Desktop Actions) doğrudan Kısayollar menüsünde tanır. Kullanıcılar Spectacle'ın yerel kısayollarını birebir Omnisnap eylemleriyle eşleştirebilir:

### Önerilen Kısayol Eşleştirmeleri:

| Eylem Adı | Çalıştırılacak Komut | Önerilen Kısayol | Açıklama |
| :--- | :--- | :--- | :--- |
| **Omnisnap Bölge Seçimi** | `omnisnap region` | `Print` veya `Shift + Print` | Etkileşimli alan yakalama tuvali |
| **Omnisnap Aktif Pencere** | `omnisnap window` | `Meta + Print` | Odaktaki aktif pencereyi anında yakalama |
| **Omnisnap Anında Tam Ekran** | `omnisnap full` | `Shift + Ctrl + Print` | Tüm masaüstünü anında yakalama |
| **Omnisnap Ayarları** | `omnisnap settings` | İsteğe bağlı | Ayar arayüzü penceresini açar |
| **Omnisnap Anında Not/Çizim** | `omnisnap edit` | `Meta + Shift + E` | Swappy ile doğrudan düzenleme |
| **Omnisnap Metin Okuma (OCR)** | `omnisnap ocr` | `Meta + Shift + T` | Tesseract ile panoya metin kopyalama |
| **Omnisnap Görsel Arama** | `omnisnap search` | `Meta + Shift + L` | Google Lens ile görsel arama |

## KWin Spectacle Kısayollarının Değiştirilmesi
KDE Plasma 6'da varsayılan olarak `Print` tuşu Spectacle GUI'sine atanmıştır. Omnisnap'i birincil ekran aracı yapmak için:
1. Shortcuts menüsünde `Spectacle` aratılır.
2. "Bölge Yakala" ve "Tam Ekran Yakala" varsayılan kısayolları kaldırılır veya değiştirilir.
3. `omnisnap region` komutuna `Print` tuşu atanır.

## İlişkili Dokümanlar
- Komut satırı kullanımı: [[cli-interface]]
- Kurulum otomasyonu: [[installation-and-packaging]]
- Yaşam döngüleri: [[execution-lifecycles]]
