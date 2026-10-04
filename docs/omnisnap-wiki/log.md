# Değişiklik ve İşlem Günlüğü (Changelog & Operational Log)

Bu dosya, Omnisnap Yaşayan Mimarisi ve kod tabanı üzerinde gerçekleştirilen ontolojik modelleme, mimari kararlar, özellik geliştirmeleri ve doğrulama adımlarının kronolojik, yalnızca-eklenebilir (append-only) kaydıdır.

Format standardı:
```text
## [YYYY-MM-DD] eylem-türü | Başlık
- Detaylar ve etkilenen sayfalar...
```

---

## [2026-10-05] [feat] | Active Window Capture and Meta+Print Integration
- **Kapsam**: Spectacle'ın yerleşik aktif pencere yakalama motorunun (`spectacle -b -n -a`) Omnisnap mimarisine entegrasyonu ve `Meta+Print` kısayol desteği.
- **Çözüm**:
  - `bin/omnisnap` betiğine `window`, `-w`, `--window`, `active` komutları eklendi (daemon IPC ve oneshot modları destekleniyor).
  - `shell.qml` içine `captureDirect(isWindow)` fonksiyonu eklenerek hem `fullscreen` hem de `window` yakalamanın `Config.qml` ayarlarıyla (kayıt dizini, dosya formatı, çözünürlük sınırı, ses ve pano) uyumlu çalışması sağlandı.
  - `omnisnap.desktop` dosyasına `[Desktop Action Window]` tanımlanarak KDE Plasma 6 Kısayollar menüsünde Spectacle'ın yerel `Meta+Print` kısayolunun doğrudan Omnisnap'e atanabilmesi sağlandı.
  - Birim testleri (`test_cli.sh`, `test_quickshell_syntax.sh`, `test_install.sh`) ve wiki dokümantasyonu güncellendi.
- **İlgili Sayfalar**: [[desktop-and-shortcuts]], [[cli-interface]], [[settings-and-configuration]], [[system-overview]].

## [2026-09-28] [feat] | Persistent Settings Page and Resolution Limits
- **Kapsam**: Omnisnap yapılandırma altyapısı (`Config.qml`), en-boy oranını koruyan çözünürlük kısıtlama boru hattı ve Quickshell `FloatingWindow` ayarlar arayüzü (`SettingsWindow.qml`).
- **Çözüm**:
  - `~/.config/omnisnap/config.json` dosyasını yöneten reaktif `Config.qml` singleton'ı geliştirildi.
  - ImageMagick kırpma komut zincirine (`cropBase`) `-resize 'WIDTHxHEIGHT>'` şartlı boyutlandırma bayrağı eklenerek en-boy oranını koruyan ve küçük görselleri büyütmeyen çözünürlük sınırlayıcı entegre edildi.
  - Bağımsız XDG penceresi (`FloatingWindow`) olarak çalışan zengin `SettingsWindow.qml` grafik arayüzü geliştirildi (Genel, Çözünürlük & Biçim, Gelişmiş sekmeleri, ön tanımlı çözünürlük butonları ve görsel kaydetme geribildirimi).
  - CLI (`omnisnap settings`, `-c`, `--settings`, `config`) ve araç çubuğu ayar butonu üzerinden hem daemon IPC hem de oneshot bağımsız modda başlatma sağlandı.
  - ADR-006 ve teknik dokümantasyon yaşayan mimari wikisine işlendi.
- **İlgili Sayfalar**: [[adr-006-settings-management-and-resolution-limits]], [[settings-and-configuration]], [[action-orchestration]], [[image-crop-pipeline]], [[floating-toolbar]], [[cli-interface]].

## [2026-09-28] feat | Dinamik Test Koşucusu ve Ajan Kuralı İyileştirmesi
- **Kapsam**: `AGENTS.md` ve test altyapısında statik test listesi bağımlılığının kaldırılması.
- **Çözüm**:
  - `tests/run-tests.sh` birleşik dinamik test koşucusu geliştirildi (`tests/test_*.sh` dosyalarını otomatik keşfeder).
  - `AGENTS.md` ve `testing-harness.md` güncellenerek tüm testlerin tek komutla (`bash tests/run-tests.sh`) çalıştırılması sağlandı; yeni testler eklendiğinde ajan kural setini güncelleme gereksinimi ortadan kaldırıldı.
- **İlgili Sayfalar**: [[testing-harness]], [[cli-interface]].

## [2026-09-28] ingest | İlk Ontolojik Modelleme ve Karpathy LLM Wiki İnşası
- **Kapsam**: Omnisnap kod tabanının baştan sona taranması, fonksiyonel domainlerin belirlenmesi ve yaşayan mimari wikisinin kurulması.
- **Oluşturulan Fonksiyonel Domainler**:
  - `architecture/`: Yüksek seviyeli sistem mimarisi, yaşam döngüleri ve çoklu monitör topolojisi.
  - `decisions/`: 5 adet kritik Mimari Karar Kaydı (ADR-001'den ADR-005'e).
  - `core-engine/`: Ekran dondurma, KWin kenar koruma sistemi ve süreç yaşam döngüsü.
  - `ui-components/`: Wayland LayerShell katmanı, seçim mekaniği, görsel kılavuzlar, kayan araç çubuğu ve tasarım sistemi.
  - `pipelines/`: Eylem orkestrasyonu, piksel kırpma, pano/bildirimler, Swappy çizim, OCR ve Google Lens görsel arama.
  - `integration/`: CLI arayüzü, masaüstü kısayolları, kurulum/kaldırma ve test altyapısı.
- **Sistem Durumu**:
  - Tüm QML bileşenleri Qt 6 `qmllint` statik denetiminden başarıyla geçmektedir.
  - 9 adet regresyon test süiti (`tests/`) hatasız çalışmaktadır.
  - KWin sıcak köşe engellemesi ve fare işaretçisi geçirgenliği doğrulanmıştır.
- **İlgili Sayfalar**: [[index]], [[system-overview]], [[adr-001-screen-freeze-via-spectacle]], [[adr-002-dual-lifecycle-oneshot-and-daemon]], [[adr-003-kwin-screen-edge-inhibition]], [[adr-004-multimodal-post-processing-pipeline]], [[adr-005-layershell-pointer-transparency]].

## [2026-09-28] fix | Ekran Kenarı Engelleme ve İşaretçi Geçirgenliği
- **Kapsam**: KWin genel bakış açılma hatası ve fare bırakıldığında kaydetmeme sorununun çözülmesi.
- **Çözüm**:
  - `bin/omnisnap-edges` geliştirildi; `stolen-screen-edges.json` ile dinamik yedekleme/geri yükleme ve kaza kurtarma eklendi.
  - `RectCornersSelectionDetails.qml` ve `CursorGuide.qml` bileşenlerine `enabled: false` atanarak işaretçi olaylarının yutulması önlendi.
  - `ScreenshotAction.qml` içerisindeki masaüstü bildirimi arka plan alt kabuğuna `( ... ) &` alınarak gecikmesiz pano kopyalama sağlandı.
- **İlgili Sayfalar**: [[screen-edge-inhibitor]], [[selection-mechanics]], [[clipboard-and-notifications]], [[adr-003-kwin-screen-edge-inhibition]], [[adr-005-layershell-pointer-transparency]].

## [2026-09-28] feat | Omnisnap Çekirdek Ekran Yakalama ve Çok Modlu Boru Hattı
- **Kapsam**: Projenin ilk sürümünün Caelestia ekran dondurma tasarımından bağımsızlaştırılarak inşa edilmesi.
- **Bileşenler**:
  - `shell.qml` ana Quickshell kabuğu ve IPC dinleyicisi.
  - `ScreenshotAction.qml` ile Copy, Edit (Swappy), Search (Google Lens) ve OCR (Tesseract) eylemleri.
  - Catppuccin Mocha / Breeze Dark uyumlu `Theme.qml` ve atomik UI bileşenleri.
  - CLI başlatıcısı `bin/omnisnap` ve `install.sh` kurulum otomasyonu.
- **İlgili Sayfalar**: [[system-overview]], [[action-orchestration]], [[design-system]], [[cli-interface]], [[installation-and-packaging]].
