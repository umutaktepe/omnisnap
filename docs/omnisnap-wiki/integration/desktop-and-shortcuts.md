# Masaüstü Girişi ve KDE Kısayolları (Desktop & Shortcuts)

Omnisnap, KDE Plasma 6 masaüstü ortamına kusursuz entegre olacak şekilde bir `.desktop` dosyası, freedesktop/KDE standartlarına uygun `X-KDE-Shortcuts` yönergeleri ve otomatik kısayol yönetim motoru (`bin/omnisnap-shortcuts`) ile donatılmıştır ([[adr-007-kde-plasma-shortcuts-kcm-integration]]).

## Masaüstü Dosyası: `omnisnap.desktop`
```ini
[Desktop Entry]
Name=Omnisnap
GenericName=Screen Capture Tool
GenericName[tr]=Ekran Görüntüsü Yakalama Aracı
Comment=Modern Screenshot Tool for KDE Plasma 6
Comment[tr]=KDE Plasma 6 İçin Modern Ekran Yakalama Aracı
Exec=omnisnap region
Icon=camera-photo
Terminal=false
Type=Application
Categories=Utility;Graphics;
Keywords=screenshot;snip;capture;ocr;lens;
Actions=Region;FullScreen;Window;Settings;
X-KDE-Shortcuts=Print

[Desktop Action Region]
Name=Capture Rectangular Region
Name[tr]=Bölge Seçimi ve Yakalama
Exec=omnisnap region
Icon=select-rectangular
X-KDE-Shortcuts=Print

[Desktop Action Window]
Name=Capture Active Window
Name[tr]=Aktif Pencereyi Yakala
Exec=omnisnap window
Icon=window
X-KDE-Shortcuts=Meta+Print

[Desktop Action FullScreen]
Name=Capture Entire Desktop
Name[tr]=Tüm Ekranı Yakala
Exec=omnisnap full
Icon=view-fullscreen
X-KDE-Shortcuts=Shift+Print

[Desktop Action Settings]
Name=Omnisnap Settings
Name[tr]=Omnisnap Ayarları
Exec=omnisnap settings
Icon=preferences-system
X-KDE-Shortcuts=Meta+Shift+Print
```

Bu dosya `install.sh` ve `bin/omnisnap-shortcuts install-desktop` tarafından `~/.local/share/applications/omnisnap.desktop` konumuna kopyalanır ve `Exec` yolları kullanıcının yerel ikili yoluna (`~/.local/bin/omnisnap` veya proje çalışma dizinine) göre dinamik olarak güncellenir ([[installation-and-packaging]]).

---

## KDE Plasma 6 KCM Keys ve `X-KDE-Shortcuts` Standardı

KDE Plasma 6, sistem kısayollarını `kcmshell6 kcm_keys` (Sistem Ayarları -> Kısayollar) modülü üzerinden yönetir. Omnisnap, harici veya yabancı bir kabuk betiği gibi "Özel Kısayol (Custom Shortcut)" olarak eklenmek yerine, sistemin yerli bir masaüstü uygulaması olarak entegre olur.

### 1. Uygulamalar (Applications) Listesinde Doğal Görünüm
- `omnisnap.desktop` dosyası `$XDG_DATA_HOME/applications/` altına kurulduğu andan itibaren KDE KCM Keys arayüzünde "Uygulamalar" kategorisi altında **Omnisnap** olarak listelenir.
- Tanımlanan tüm `[Desktop Action ...]` blokları hiyerarşik alt eylemler olarak (Bölge Seçimi, Aktif Pencere, Tüm Ekran, Ayarlar) doğrudan Spectacle'ın hemen yanında görüntülenir.
- Her eylemin simgesi (`Icon`) ve iki dilli açıklaması (`Name[tr]`, `Comment[tr]`) Sistem Ayarları arayüzünde eksiksiz işlenir.

### 2. Standart Fabrika Değerleri ve "Varsayılana Sıfırla" Uyumluluğu
- Masaüstü dosyasındaki `X-KDE-Shortcuts` anahtarları, KDE KGlobalAccel için resmi fabrika varsayılanlarını (Default Shortcuts) belirler.
- Kullanıcı Sistem Ayarları arayüzünde kısayolu değiştirse bile dilediği zaman "Varsayılana Sıfırla (Reset to Defaults)" butonuna basarak `X-KDE-Shortcuts` değerlerine dönebilir.

### Varsayılan Kısayol Eşleştirmeleri:

| Eylem (Action) | Desktop Action | Kısayol | KGlobalAccel Açıklaması |
| :--- | :--- | :--- | :--- |
| **Ana Başlatıcı** | `_launch` | `Print` | Launch Omnisnap |
| **Bölge Seçimi** | `Region` | `Print` | Capture Rectangular Region |
| **Aktif Pencere** | `Window` | `Meta + Print` | Capture Active Window |
| **Tüm Ekran** | `FullScreen` | `Shift + Print` | Capture Entire Desktop |
| **Ayarlar** | `Settings` | `Meta + Shift + Print` | Omnisnap Settings |

---

## İlk Çalıştırmada Sessiz Öz-Kayıt (`_ensure_desktop_and_shortcuts`)

Kullanıcının kurulum sonrasında manuel terminal komutları girmesine gerek kalmaması için `bin/omnisnap` ana başlatıcısına hafif ve şeffaf bir kontrol kancası (`_ensure_desktop_and_shortcuts`) eklenmiştir:

```bash
_ensure_desktop_and_shortcuts() {
    local desktop_file="${OMNISNAP_DESKTOP_TARGET:-${XDG_DATA_HOME:-$HOME/.local/share}/applications}/omnisnap.desktop"
    if [ ! -f "$desktop_file" ] || ! grep -q "X-KDE-Shortcuts" "$desktop_file" 2>/dev/null; then
        "$PROJECT_DIR/bin/omnisnap-shortcuts" apply-defaults >/dev/null 2>&1 || true
    fi
}
```

- Kullanıcı `omnisnap` komutunu ister terminalden, ister uygulama menüsünden ilk kez çalıştırdığında bu fonksiyon tetiklenir.
- Eğer `omnisnap.desktop` henüz kurulmamışsa veya güncel `X-KDE-Shortcuts` bildirimlerini içermiyorsa, arka planda sessizce `omnisnap-shortcuts apply-defaults` yürütülür.
- Kullanıcı hiçbir ek işlem yapmadan tüm tuş kombinasyonları KGlobalAccel'e kaydedilir ve Spectacle çakışmaları çözülür.

---

## Kısayol Motoru: `bin/omnisnap-shortcuts`

Omnisnap, kısayol yapılandırmasını programatik yöneten `bin/omnisnap-shortcuts` CLI motoruna sahiptir:

```bash
omnisnap-shortcuts <komut> [argümanlar]
```

### Alt Komutlar ve İşlevleri:
1. `install-desktop`: `omnisnap.desktop` dosyasını `~/.local/share/applications/` altına kopyalar, `Exec` yollarını mutlak konuma uyarlar ve `update-desktop-database` ile KDE masaüstü veritabanını günceller.
2. `apply-defaults`:
   - `install-desktop` adımını garantiye alır.
   - `~/.config/kglobalshortcutsrc` dosyasına `[services][omnisnap.desktop]` grubu altında dost isim (`_k_friendly_name="Omnisnap"`), `_launch` ve 4 temel eylemi kaydeder.
   - Çakışan Spectacle kısayollarını (`RectangularRegionScreenShot`, `ActiveWindowScreenShot`, `FullScreenScreenShot`) devre dışı bırakır (`none`).
   - Son anahtar yazılırken `kwriteconfig6 --notify` bayrağı ile KDE KGlobalAccel servisine anında bildirim gönderir (oturumun yeniden başlatılması gerekmez).
3. `set <action> <key>`: Belirli bir eylemin (Region, Window, FullScreen, Settings) kısayolunu anında günceller.
4. `get <action>`: İlgili eylemin mevcut kısayol değerini döndürür.
5. `status`: Tanımlı tüm Omnisnap kısayollarını terminalde tablo biçiminde listeler.

### Çift Katmanlı KConfig Yazma Motoru:
- **Birincil Motor**: KDE'nin yerel `kwriteconfig6` ve `kreadconfig6` araçları.
- **Güvenli Fallback**: Python 3 `configparser.RawConfigParser(optionxform=str)`. Büyük/küçük harf duyarlılığını koruyarak ve `[group1][group2]` çiftli KDE grup sözdizimini hatasız işleyerek `kglobalshortcutsrc` dosyasını manipüle eder.

---

## Uygulama İçi (In-App) Ayarlar Entegrasyonu

Kullanıcı `SettingsWindow.qml` içerisindeki "Klavye Kısayolları" sekmesini açtığında:
- "KDE'ye Tanımla & Eşitle" butonuna basarak tüm varsayılanları tek tıkla arka planda sisteme tanıtabilir (`Config.applyKdeShortcuts()`).
- "KDE Kısayol Ayarlarını Aç" butonuna basarak doğrudan `kcmshell6 kcm_keys` penceresine geçiş yapabilir.
- Her eylemin tuş kombinasyonunu metin kutusundan doğrudan değiştirip "Uygula" butonuna basarak anında KDE'ye işletebilir.

---

## İlişkili Dokümanlar
- Mimari Karar Kaydı: [[adr-007-kde-plasma-shortcuts-kcm-integration]]
- Komut Satırı Arayüzü: [[cli-interface]]
- Ayarlar ve Yapılandırma: [[settings-and-configuration]]
- Kurulum ve Paketleme: [[installation-and-packaging]]
- Yaşam Döngüleri: [[execution-lifecycles]]
- Test Mimarisi: [[testing-harness]]
