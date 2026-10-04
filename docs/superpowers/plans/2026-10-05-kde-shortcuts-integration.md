# KDE Plasma KCM Shortcuts Entegrasyonu ve Otomatik Kayıt Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Spectacle gibi Omnisnap'in de KDE Sistem Ayarları (`kcm_keys` -> Shortcuts -> Applications) altında varsayılan olarak kendi adıyla listelenmesini, tüm alt eylemlerinin (`Region`, `Window`, `FullScreen`, `Settings`) önceden tanımlanmış `X-KDE-Shortcuts` kısayollarıyla görünmesini ve uygulama kurulup ilk açıldığında arka planda hiçbir kullanıcı müdahalesine gerek kalmadan sisteme otomatik işlenmesini sağlamak.

**Architecture:** KDE Plasma 6 KGlobalAccel ve KCM Keys mimarisine tam uyum sağlamak için `omnisnap.desktop` dosyası kök ve eylem düzeyinde `X-KDE-Shortcuts` standart direktifleriyle donatılır. `bin/omnisnap-shortcuts`, `install.sh`, `bin/omnisnap` başlatıcısı ve `Config.qml` ilk çalıştırma döngüsünde masaüstü girişini `~/.local/share/applications/` altına kurup `update-desktop-database` ve `kwriteconfig6 --notify` ile KDE servis ağacına otomatik kaydeder.

**Tech Stack:** FreeDesktop XDG Desktop Entry Specification, KDE Plasma 6 KGlobalAccel (`kglobalshortcutsrc`), `kwriteconfig6`, `kreadconfig6`, Quickshell QML, Bash.

**Spec:** Kullanıcı isteği ve sistem ayarları ekran görüntüsü (`media_1791151192931.png`).

## Global Constraints
- Karpathy "Living Architecture" dokümantasyon kurallarına (`AGENTS.md`) sıkı sıkıya bağlı kalınacaktır.
- Tüm QML dosyaları Qt 6 `qmllint` denetiminden sıfır hata ve sıfır uyarıyla geçecektir.
- Tüm test süitleri (`bash tests/run-tests.sh`) 12/12 başarıyla geçecektir.
- Kısayol kaydetme ve masaüstü dosyası kurulumu kullanıcı müdahalesi gerektirmeden arka planda sessizce gerçekleşecektir.
- Çakışan varsayılan Spectacle kısayolları güvenli bir şekilde unbind edilerek Omnisnap önceliklendirilecektir.

---

## Görevler ve Dosya Yapısı

- `omnisnap.desktop`: Kök düzeyde ve 4 Desktop Action (`Region`, `Window`, `FullScreen`, `Settings`) altında `X-KDE-Shortcuts` ve Türkçe yerelleştirilmiş ad tanımları eklenir.
- `bin/omnisnap-shortcuts`: Desktop dosyasındaki `X-KDE-Shortcuts` direktiflerini koruyarak `~/.local/share/applications/` altına kuran ve `kglobalshortcutsrc` içine `_k_friendly_name` ve eylem tanımlarını `--notify` ile yazan CLI motoru güçlendirilir.
- `bin/omnisnap`: İlk çalıştırmada veya oneshot/daemon başlatıldığında masaüstü dosyasının ve kısayolların kurulu olup olmadığını kontrol eden, eksikse otomatik kuran koruma fonksiyonu eklenir.
- `modules/config/Config.qml` & `modules/settings/SettingsWindow.qml`: "KDE'de Aç" butonuna basıldığında KDE pencereleri açılmadan önce masaüstü kaydını güncelleyen el sıkışma sağlanır.
- `tests/test_shortcuts.sh`: `omnisnap.desktop` `X-KDE-Shortcuts` alanlarını, otomatik kurulumu ve KGlobalAccel bildirimlerini doğrulayan yeni test senaryoları eklenir.
- `docs/omnisnap-wiki/`: Yaşayan mimari dokümantasyonu ve işlem günlüğü (`log.md`) güncellenir.

---

### Görev 1: `omnisnap.desktop` Dosyasının KDE Standart `X-KDE-Shortcuts` Direktifleriyle Donatılması

**Dosyalar:**
- Değiştir: `omnisnap.desktop:1-35`
- Test: `tests/test_shortcuts.sh`

**Arayüzler:**
- `X-KDE-Shortcuts=Print`: Ana `[Desktop Entry]` altında varsayılan başlatıcı kısayolu.
- `[Desktop Action Region]`: `X-KDE-Shortcuts=Print`
- `[Desktop Action Window]`: `X-KDE-Shortcuts=Meta+Print`
- `[Desktop Action FullScreen]`: `X-KDE-Shortcuts=Shift+Print`
- `[Desktop Action Settings]`: `X-KDE-Shortcuts=Meta+Shift+Print`

- [ ] **Adım 1: Başarısız testi yaz (`tests/test_shortcuts.sh`)**
  `omnisnap.desktop` dosyasının kök düzeyde ve her Desktop Action altında `X-KDE-Shortcuts` içerdiğini kontrol eden `test_desktop_entry_kde_shortcuts` fonksiyonu ekle.
- [ ] **Adım 2: Testi çalıştır ve başarısız olduğunu gör**
  `bash tests/test_shortcuts.sh`
- [ ] **Adım 3: `omnisnap.desktop` dosyasını güncelle**
  Spectacle spesifikasyonuna uygun olarak `GenericName`, `X-KDE-Shortcuts` ve Türkçe açıklamaları ekle.
- [ ] **Adım 4: Testi çalıştır ve geçtiğini doğrula**
  `bash tests/test_shortcuts.sh`
- [ ] **Adım 5: Commit**
  `git commit -m "feat(desktop): add X-KDE-Shortcuts directives to omnisnap.desktop"`

---

### Görev 2: `bin/omnisnap-shortcuts` CLI Motorunun Geliştirilmesi ve KGlobalAccel Uyumu

**Dosyalar:**
- Değiştir: `bin/omnisnap-shortcuts:60-120`
- Test: `tests/test_shortcuts.sh`

**Arayüzler:**
- `install_desktop`: `omnisnap.desktop` dosyasını `~/.local/share/applications` altına kurar, `Exec=` yolunu günceller ve `update-desktop-database` çalıştırır.
- `apply_defaults`:
  - `_k_friendly_name=Omnisnap`
  - `_launch=Print,Print,Launch Omnisnap`
  - `Region=Print,Print,Capture Rectangular Region`
  - `Window=Meta+Print,Meta+Print,Capture Active Window`
  - `FullScreen=Shift+Print,Shift+Print,Capture Entire Desktop`
  - `Settings=Meta+Shift+Print,Meta+Shift+Print,Omnisnap Settings`
  - `--notify` bayrağı ile KDE Plasma KGlobalAccel oturumunu anında günceller.

- [ ] **Adım 1: Testi güncelle (`tests/test_shortcuts.sh`)**
  `apply_defaults` çalıştırıldığında `_launch` ve `_k_friendly_name` alanlarının da `kglobalshortcutsrc` dosyasına yazıldığını doğrula.
- [ ] **Adım 2: Testi çalıştır ve başarısız olduğunu gör**
  `bash tests/test_shortcuts.sh`
- [ ] **Adım 3: `bin/omnisnap-shortcuts` dosyasını güncelle**
  `apply_defaults` fonksiyonuna `_launch` ve `_k_friendly_name` direktiflerini ekle, `install_desktop` sırasında `X-KDE-Shortcuts` alanlarının bozulmadan kopyalandığından emin ol.
- [ ] **Adım 4: Testi çalıştır ve geçtiğini doğrula**
  `bash tests/test_shortcuts.sh`
- [ ] **Adım 5: Commit**
  `git commit -m "feat(shortcuts): enhance apply-defaults with KGlobalAccel friendly name and launch keys"`

---

### Görev 3: İlk Çalıştırmada Otomatik Kurulum ve KDE Senkronizasyonu (`bin/omnisnap` & `Config.qml`)

**Dosyalar:**
- Değiştir: `bin/omnisnap:30-70`
- Değiştir: `modules/config/Config.qml:110-125`
- Değiştir: `modules/settings/SettingsWindow.qml:990-1040`
- Test: `tests/test_cli.sh`

**Arayüzler:**
- `_ensure_desktop_and_shortcuts()`: `bin/omnisnap` başlatıldığında `~/.local/share/applications/omnisnap.desktop` dosyasının varlığını ve `X-KDE-Shortcuts` içerip içermediğini denetler. Yoksa sessizce `omnisnap-shortcuts apply-defaults` çalıştırır.
- `SettingsWindow.qml`: "KDE'de Aç" butonuna tıklandığında önce `Config.applyKdeShortcuts()` çalıştırır, ardından `kcmshell6 kcm_keys` açar; böylece kullanıcı sistem ayarlarına girdiğinde Omnisnap kesin olarak listelenmiş olur.

- [ ] **Adım 1: Testi güncelle (`tests/test_cli.sh`)**
  `bin/omnisnap` betiğinin ilk çalıştırma durumunda otomatik desktop dosyasını kurma fonksiyonunu çağırdığını doğrulayan bir test ekle.
- [ ] **Adım 2: Testi çalıştır ve başarısız olduğunu gör**
  `bash tests/test_cli.sh`
- [ ] **Adım 3: `bin/omnisnap`, `Config.qml` ve `SettingsWindow.qml` dosyalarını güncelle**
  İlk çalıştırmada sessiz kurulum ve senkronizasyon kontrollerini bağla.
- [ ] **Adım 4: Testleri ve `qmllint` denetimini çalıştır**
  `bash tests/test_cli.sh` ve `qmllint` doğrulaması yap.
- [ ] **Adım 5: Commit**
  `git commit -m "feat(core): auto-register desktop and KDE shortcuts on first app launch"`

---

### Görev 4: Dokümantasyon, Bütünsel Test Süiti ve Yaşayan Mimari

**Dosyalar:**
- Güncelle: `docs/omnisnap-wiki/integration/desktop-and-shortcuts.md`
- Güncelle: `docs/omnisnap-wiki/decisions/adr-007-kde-plasma-shortcuts-kcm-integration.md` (yeni ADR)
- Güncelle: `docs/omnisnap-wiki/index.md`
- Güncelle: `docs/omnisnap-wiki/log.md`

- [ ] **Adım 1: Yeni ADR oluştur (`adr-007-kde-plasma-shortcuts-kcm-integration.md`)**
  KDE Plasma 6 KCM Keys altında Spectacle gibi yerel listelenme kararını (Bağlam, Alternatifler, Karar, Sonuçlar) dokümante et.
- [ ] **Adım 2: Bütün test takımını çalıştır (`tests/run-tests.sh`)**
  Tüm 12 test dosyasının %100 başarıyla geçtiğini doğrula.
- [ ] **Adım 3: Yaşayan mimari dokümanlarını ve fihristi (`index.md`) güncelle**
- [ ] **Adım 4: `log.md` dosyasına append-only kayıt ekle**
- [ ] **Adım 5: Final commit ve push**
  `git push origin master`
