# Arayüz Oranları, Popover Hizalaması ve Uygulama İçi Kısayol Yönetimi Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ekran seçim araç çubuğundaki popover menüsünü buton üzerine sabitlemek, ayarlar penceresindeki sekme taşmalarını ve boyut oranlarını düzeltmek; harici KDE pencerelerine gitmeye gerek kalmadan doğrudan Omnisnap arayüzünden kısayolları düzenleyip arka planda sisteme işleyen yerleşik kısayol motorunu hayata geçirmek.

**Architecture:** `OptionsToolbar.qml` içinde açılır menü `fsBtn` ebeveynine bağlanarak milimetrik koordinat uyumu sağlanır. `SettingsWindow.qml` pencere boyutları genişletilip sekmeler yatay kaydırmalı/özlü hale getirilir. Yeni `bin/omnisnap-shortcuts` aracı ve `Config.qml` entegrasyonuyla `~/.local/share/applications/omnisnap.desktop` otomatik olarak sisteme tanıtılır ve kullanıcı ayarları doğrudan `kwriteconfig6` ile KDE KGlobalAccel katmanına arka planda tek tıkla işlenir.

**Tech Stack:** Qt 6 / Quickshell, QML (Quick Layouts, Controls), Bash, `kwriteconfig6`, `kreadconfig6`, Linux XDG Desktop Entry Specification.

**Spec:** Kullanıcı geri bildirimi ve hata ekran görüntüsü (`media_1791150464827.png`).

## Global Constraints
- Karpathy "Living Architecture" dokümantasyon kurallarına (`AGENTS.md`) sıkı sıkıya bağlı kalınacaktır.
- Tüm QML dosyaları Qt 6 `qmllint` denetiminden sıfır hata ve sıfır uyarıyla geçecektir.
- Tüm test süitleri (`bash tests/run-tests.sh`) 11/11 başarıyla geçecektir.
- Kısayol kaydetme ve .desktop senkronizasyonu kullanıcıyı harici pencerelere zorunlu kılmadan arka planda asenkron çalışacaktır.

---

## Görevler ve Dosya Yapısı

- `modules/screenshot/regionSelector/OptionsToolbar.qml`: `captureModeMenu` popover menüsünü doğrudan `fsBtn` içine taşıyarak sol kayma sorununu çözmek.
- `modules/settings/SettingsWindow.qml`: Pencere boyutlarını ferahlatmak (`740x560`), sekme taşmalarını önlemek, kısayol özelleştirme ve tek tıkla KDE'ye arka planda işleme kontrollerini eklemek.
- `bin/omnisnap-shortcuts`: Kısayolları `kglobalshortcutsrc` ve `.desktop` dosyasına doğrudan yazan, okuyan ve `update-desktop-database` ile sisteme bildiren CLI motoru.
- `modules/config/Config.qml`: Kısayol yapılandırmasını (`shortcuts` JSON alanı) tutan ve `bin/omnisnap-shortcuts` ile senkronize eden yapı.
- `tests/test_shortcuts.sh`: Kısayol motoru, `kwriteconfig6` parametreleri ve `.desktop` entegrasyonu için yeni test süiti.
- `tests/test_toolbar.sh`: Popover hiyerarşi ve konum doğrulamaları.
- `tests/test_settings_syntax.sh`: Yeni sekme düzeni ve kısayol motoru QML sözdizimi doğrulamaları.
- `docs/omnisnap-wiki/`: Yaşayan mimari dokümantasyonunun ve işlem günlüğünün (`log.md`) güncellenmesi.

---

### Görev 1: Popover Hizalama Hatasının Düzeltilmesi (`OptionsToolbar.qml`)

**Dosyalar:**
- Değiştir: `modules/screenshot/regionSelector/OptionsToolbar.qml:80-160`
- Test: `tests/test_toolbar.sh`

**Arayüzler:**
- `fsBtn`: IconButton bileşeni. `captureModeMenu` doğrudan bu bileşenin alt elemanı (child) yapılır.
- `anchors.horizontalCenter: parent.horizontalCenter`: Doğrudan `fsBtn`'in yatay merkezine kilitlenir.

- [ ] **Adım 1: Başarısız testi yaz / güncelle (`tests/test_toolbar.sh`)**
  Popover menüsünün `fsBtn` içerisinde doğrudan alt eleman olarak yer aldığını ve `parent.horizontalCenter` kullandığını doğrulayan bir test ekle.
- [ ] **Adım 2: Testi çalıştır ve başarısız olduğunu gör**
  `bash tests/test_toolbar.sh`
- [ ] **Adım 3: `OptionsToolbar.qml` dosyasını düzelt**
  `captureModeMenu` bloğunu `root` altından alıp `IconButton { id: fsBtn ... }` içerisine taşı; `horizontalCenter: parent.horizontalCenter` ve `bottom: parent.top` ata.
- [ ] **Adım 4: Testi çalıştır ve geçtiğini doğrula**
  `bash tests/test_toolbar.sh` ve `qmllint modules/screenshot/regionSelector/OptionsToolbar.qml`
- [ ] **Adım 5: Commit**
  `git commit -m "fix(ui): anchor captureModeMenu directly inside fsBtn to eliminate coordinate offset"`

---

### Görev 2: Ayarlar Penceresi Oranları ve Sekme Taşmalarının Düzeltilmesi (`SettingsWindow.qml`)

**Dosyalar:**
- Değiştir: `modules/settings/SettingsWindow.qml:10-185`
- Test: `tests/test_settings_syntax.sh`

**Arayüzler:**
- Pencere boyutları: `implicitWidth: 740`, `implicitHeight: 560`, `minimumSize.width: 680`, `minimumSize.height: 500`.
- Sekme başlıkları ve sarmalayıcı: Sekmeler `Flickable` içine alınarak yatay taşma riski sıfırlanır, isimler daha öz ve okunaklı hale getirilir (`Çözünürlük`, `Depolama & Pano`, `Arayüz`, `Kısayollar`, `OCR`).

- [ ] **Adım 1: Testi güncelle (`tests/test_settings_syntax.sh`)**
  Pencere genişlik ve sekme sarmalama kontrollerini ekle.
- [ ] **Adım 2: Testi çalıştır**
  `bash tests/test_settings_syntax.sh`
- [ ] **Adım 3: `SettingsWindow.qml` oranlarını ve sekme çubuğunu yeniden yapılandır**
  Pencere boyutlarını 740x560 yap; sekmeleri esnek `Flickable` kapsayıcısına al; etiketleri dengeli ve şık hale getir.
- [ ] **Adım 4: `qmllint` ve testleri çalıştır**
  `qmllint` ve `bash tests/test_settings_syntax.sh` doğrula.
- [ ] **Adım 5: Commit**
  `git commit -m "fix(ui): adjust settings window proportions and wrap tab bar to prevent overflow"`

---

### Görev 3: Arka Plan Kısayol Senkronizasyon Motoru (`bin/omnisnap-shortcuts` & `install.sh`)

**Dosyalar:**
- Oluştur: `bin/omnisnap-shortcuts`
- Değiştir: `install.sh`
- Test: `tests/test_shortcuts.sh`

**Arayüzler:**
- `omnisnap-shortcuts install-desktop`: `~/.local/share/applications/omnisnap.desktop` dosyasını kurar ve `update-desktop-database` çalıştırır.
- `omnisnap-shortcuts apply-defaults`: `kglobalshortcutsrc` dosyasına `[services][omnisnap.desktop]` altında Region, Window, FullScreen ve Settings kısayollarını yazar ve `--notify` bayrağını gönderir.
- `omnisnap-shortcuts set <action> <key>`: Tekil kısayolu günceller.
- `omnisnap-shortcuts get <action>`: Kısayolun geçerli değerini döndürür.

- [ ] **Adım 1: Başarısız test yaz (`tests/test_shortcuts.sh`)**
  Betiğin `install-desktop`, `apply-defaults`, `set`, `get` komutlarını ve `kwriteconfig6` kullanımını test eden test yaz.
- [ ] **Adım 2: Testi çalıştır ve başarısız olduğunu gör**
  `bash tests/test_shortcuts.sh`
- [ ] **Adım 3: `bin/omnisnap-shortcuts` betiğini geliştir ve `chmod +x` yap**
  KDE Plasma 6 `kwriteconfig6` ve `kreadconfig6` CLI araçlarını kullanarak arka planda sessizce kısayol yazan betiği yaz.
- [ ] **Adım 4: Testleri çalıştır ve geçtiğini doğrula**
  `bash tests/test_shortcuts.sh`
- [ ] **Adım 5: Commit**
  `git commit -m "feat(core): add background shortcut sync engine via kwriteconfig6 and desktop installer"`

---

### Görev 4: Ayarlar Penceresinde Uygulama İçi Kısayol Düzenleme ve Arka Plan Senkronizasyonu

**Dosyalar:**
- Değiştir: `modules/settings/SettingsWindow.qml`
- Değiştir: `modules/config/Config.qml`
- Test: `tests/test_settings_syntax.sh`

**Arayüzler:**
- `SettingsWindow.qml` (Kısayollar Sekmesi):
  - Üst Kart: ⚡ **"Varsayılan Kısayolları KDE'ye Tanımla"** butonu: Tıklandığında kullanıcıyı hiçbir yere yönlendirmeden arka planda `omnisnap-shortcuts apply-defaults` çalıştırır ve 2 saniye içinde "Kısayollar KDE'ye başarıyla işlendi!" onay rozetini gösterir.
  - Kart Listesi: Her eylem için (Bölge, Aktif Pencere, Tam Ekran, Ayarlar):
    - Tuş kombinasyonu metin girişi / düzenleyicisi (Örn: `Print`, `Meta+Print`).
    - Değiştirildiğinde doğrudan `Config` ve `omnisnap-shortcuts set <action> <key>` üzerinden KDE'ye otomatik kaydedilir.
- `Config.qml`: Otomatik masaüstü dosyası kontrolü (`ensureDesktopInstalled()`).

- [ ] **Adım 1: Testi güncelle (`tests/test_settings_syntax.sh`)**
  Ayarlar penceresindeki tek tıkla KDE senkronizasyon ve kısayol düzenleme elemanlarını doğrula.
- [ ] **Adım 2: `Config.qml` içine kısayol alanlarını ve sync metodunu ekle**
- [ ] **Adım 3: `SettingsWindow.qml` Kısayollar sekmesini zenginleştir**
  Kullanıcının uygulama içinden tuş kombinasyonlarını değiştirebilmesini ve tek tıkla KDE'ye doğrudan işleyebilmesini sağla.
- [ ] **Adım 4: Testleri ve `qmllint`'i çalıştır**
  `bash tests/test_settings_syntax.sh` ve `qmllint` doğrulaması yap.
- [ ] **Adım 5: Commit**
  `git commit -m "feat(settings): allow direct in-app shortcut editing and one-click background KDE sync"`

---

### Görev 5: Dokümantasyon, Bütünsel Test Süiti ve Yaşayan Mimari

**Dosyalar:**
- Güncelle: `docs/omnisnap-wiki/core-engine/settings-and-configuration.md`
- Güncelle: `docs/omnisnap-wiki/integration/desktop-and-shortcuts.md`
- Güncelle: `docs/omnisnap-wiki/ui-components/floating-toolbar.md`
- Güncelle: `docs/omnisnap-wiki/log.md`

- [ ] **Adım 1: Bütün test takımını çalıştır (`tests/run-tests.sh`)**
  Tüm 11+ test dosyasının (yeni testle birlikte 12 test süiti) %100 başarıyla geçtiğini doğrula.
- [ ] **Adım 2: Yaşayan mimari dokümanlarını güncelle**
  Popover hizalama kuralı, yeni pencere boyutları ve `omnisnap-shortcuts` CLI motorunu wikilinklerle dokümante et.
- [ ] **Adım 3: `log.md` dosyasına append-only kayıt ekle**
- [ ] **Adım 4: Final commit ve push**
  `git push origin master`
