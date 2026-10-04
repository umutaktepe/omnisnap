# Ekran Kenarı Engelleme Sistemi (Screen Edge Inhibitor)

Ekran Kenarı Engelleme Sistemi (`bin/omnisnap-edges`), kullanıcının ekran köşelerine veya kenarlarına kadar seçim yaparken KWin sıcak köşelerinin (özellikle Genel Bakış / Overview efektinin) kazara tetiklenmesini önleyen özel bir yönetim mekanizmasıdır.

Mimari kararın detayları için bkz: [[adr-003-kwin-screen-edge-inhibition]].

## Görev ve Çalışma Mantığı
KDE Plasma 6'da ekran kenarı eylemleri `kwinrc` yapılandırma dosyasında tutulur:
- `[Effect-overview]` grubunda `BorderActivate`: Genel bakış modunu tetikleyen köşe numarası (ör. sol üst köşe).
- `[ElectricBorders]` grubunda `TopLeft`, `TopRight`, `BottomLeft`, `BottomRight`: Kenar eylemleri.

### Alt Komutlar:

### 1. `omnisnap-edges inhibit`
Seçim arayüzü açılmadan hemen önce çağrılır:
1. `kreadconfig6` ile mevcut köşe yapılandırmalarını okur.
2. Ayarları `$XDG_RUNTIME_DIR/omnisnap/stolen-screen-edges.json` dosyasına güvenli bir JSON olarak yazar:
```json
{
  "Effect-overview": {
    "BorderActivate": "9"
  },
  "ElectricBorders": {
    "TopLeft": "None",
    "TopRight": "None",
    "BottomLeft": "None",
    "BottomRight": "None"
  }
}
```
3. `kwriteconfig6` ile `BorderActivate` değerini `9` (ElectricNone) yapar ve elektrikli kenarları `None` olarak ayarlar.
4. KWin ve efekt yapılandırmasını anında yeniden yükler:
```bash
gdbus call --session --dest org.kde.KWin --object-path /KWin --method org.kde.KWin.reconfigure
gdbus call --session --dest org.kde.KWin --object-path /Effects --method org.kde.kwin.Effects.reconfigureEffect overview
```

### 2. `omnisnap-edges restore`
Seçim bittiğinde (`snip` veya `dismiss`) çağrılır:
1. `$XDG_RUNTIME_DIR/omnisnap/stolen-screen-edges.json` dosyasını `jq` ile ayrıştırır.
2. Kullanıcının orijinal ayarlarını `kwriteconfig6` ile birebir eski haline yazar.
3. Durum dosyasını siler ve KWin'i yeniden reconfigure eder.

### 3. `omnisnap-edges recover`
Hata ve çökme kurtarma mekanizmasıdır:
- Eğer önceki bir oturum anormal şekilde sonlanmışsa (örneğin elektrik kesintisi veya SIGKILL), diskte `stolen-screen-edges.json` dosyası kalır.
- `bin/omnisnap` CLI aracı her başlatıldığında ilk iş olarak `omnisnap-edges recover` çalıştırarak askıda kalan durumu anında onarır.

## Test Koruması
Bu mekanizma `tests/test_screen_edges.sh` dosyasında tam izolasyon altında test edilmektedir (`OMNISNAP_TEST_MODE=1` moduyla sahte ortam dizinlerinde döngüsel yedekleme/geri yükleme doğrulanır).

## İlişkili Dokümanlar
- CLI giriş noktası: [[cli-interface]]
- Seçim arayüzü tetikleyicisi: [[layershell-overlay]]
- Mimari karar: [[adr-003-kwin-screen-edge-inhibition]]
