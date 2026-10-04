# Değişiklik ve İşlem Günlüğü (Changelog & Operational Log)

Bu dosya, Omnisnap Yaşayan Mimarisi ve kod tabanı üzerinde gerçekleştirilen ontolojik modelleme, mimari kararlar, özellik geliştirmeleri ve doğrulama adımlarının kronolojik, yalnızca-eklenebilir (append-only) kaydıdır.

Format standardı:
```text
## [YYYY-MM-DD] eylem-türü | Başlık
- Detaylar ve etkilenen sayfalar...
```

---

## [2026-10-05] [feat] | Active Window Capture Popover and Shortcuts Settings Tab
- **Kapsam**: Seçim araç çubuğuna açılır yakalama modu menüsü (Tüm Ekran / Aktif Pencere) eklenmesi ve Ayarlar penceresine KDE KGlobalAccel entegrasyonlu Klavye Kısayolları sekmesinin kazandırılması.
- **Çözüm**:
  - `OptionsToolbar.qml`: Tam Ekran butonuna tıklandığında yukarı doğru açılan Catppuccin temalı `captureModeMenu` popover menüsü eklendi (`Tüm Ekran` ve `Aktif Pencere` seçenekleri).
  - `RegionSelection.qml`, `RegionSelector.qml` ve `shell.qml`: `activeWindowRequested` sinyali ve temizlik zinciri bağlanarak aktif pencere seçildiği anda ekran seçim katmanının temizlenmesi ve `captureDirect(true)` ile odaklanılan pencerenin anında çekilmesi sağlandı.
  - `SettingsWindow.qml`: 5. sekme olarak "Klavye Kısayolları" eklendi; 4 temel eylem (Bölge Seçimi, Aktif Pencere, Tüm Ekran, Ayarlar) için `<kbd>` rozetleri ve doğrudan KDE Sistem Ayarları Kısayollar modülünü açan `kcmshell6 kcm_keys` entegrasyon butonu yerleştirildi.
  - `Icon.qml`: Klavye (`keyboard` -> `input-keyboard`) simgesi eşlemesi eklendi.
  - Tüm test süitleri (`test_toolbar.sh`, `test_settings_syntax.sh`, `test_quickshell_syntax.sh`, `run-tests.sh`) güncellendi ve 11/11 başarıyla doğrulandı.
- **İlgili Sayfalar**: [[floating-toolbar]], [[settings-and-configuration]], [[desktop-and-shortcuts]], [[selection-mechanics]].

## [2026-10-05] [fix] | Eliminate QML Runtime Keys and QQmlEngine::quit Warnings
- **Kapsam**: `SettingsWindow.qml` başlatıldığında oluşan geçersiz `Keys` iliştirme uyarısı ve süreç kapanışlarında dinleyicisi olmayan `QQmlEngine::quit()` sinyal uyarısının giderilmesi.
- **Çözüm**:
  - `SettingsWindow.qml` kökündeki `FloatingWindow` (bir `Item` olmadığı için `Keys` desteklemeyen) üzerinden `Keys.onEscapePressed` kaldırıldı; odaklı iç `Item` (`container`) ile `Escape` yakalama korundu ve `show()` fonksiyonuna `container.forceActiveFocus()` eklendi.
  - Quickshell'in C++ katmanında dinleyicisi bulunmayan `Qt.quit()` çağrıları (`SettingsWindow.qml`, `shell.qml` ve `RegionSelector.qml`), Quickshell'in yerleşik temiz çıkış mekanizması olan `Quickshell.execDetached(["kill", "-TERM", `${Quickshell.processId}`])` ile değiştirildi.
  - `test_quickshell_syntax.sh` regresyon testi güncellendi ve 11 test takımının tamamı başarıyla doğrulandı.
- **İlgili Sayfalar**: [[settings-and-configuration]], [[system-overview]], [[selection-mechanics]].

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

## [2026-10-05] fix | UI Oranları, Popover Koordinat Hizalaması ve Uygulama İçi Kısayol Senkronizasyonu
- **Kapsam**: Ekran seçim araç çubuğundaki popover hizalama hatasının, ayarlar penceresindeki sekme taşmalarının ve harici KDE bağımlılığı olmadan doğrudan uygulama içinden kısayol yönetimi ihtiyacının çözülmesi.
- **Bileşenler**:
  - `OptionsToolbar.qml`: `captureModeMenu` popover menüsü doğrudan `fsBtn` içine taşınarak `anchors.horizontalCenter: parent.horizontalCenter` ile sol sapma giderildi.
  - `SettingsWindow.qml`: Pencere boyutları `740x560` (asgari `680x500`) olarak güncellendi; sekmeler yatay `Flickable` içine alınarak taşma önlendi.
  - `bin/omnisnap-shortcuts`: KDE Plasma 6 `kwriteconfig6` ve `kreadconfig6` araçlarıyla `kglobalshortcutsrc` ve `.desktop` dosyalarını arka planda sessizce senkronize eden bağımsız CLI motoru geliştirildi.
  - `modules/config/Config.qml`: `shortcutRegion`, `shortcutWindow`, `shortcutFullScreen`, `shortcutSettings` yapılandırma alanları, otomatik desktop kurulumu ve `applyKdeShortcuts()` / `setKdeShortcut()` entegrasyonu eklendi.
  - `tests/test_shortcuts.sh`: Kısayol motorunu, `.desktop` kurulumunu ve `kglobalshortcutsrc` yazma/okuma işlevlerini test eden yeni test süiti eklendi.
- **İlgili Sayfalar**: [[floating-toolbar]], [[settings-and-configuration]], [[desktop-and-shortcuts]], [[cli-interface]], [[installation-and-packaging]].
