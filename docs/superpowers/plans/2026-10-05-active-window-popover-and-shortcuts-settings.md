# Aktif Pencere Açılır Menüsü ve Kısayol Ayarları Uygulama Planı

Bu plan, ekran seçim araç çubuğuna (OptionsToolbar) Tam Ekran butonuna tıklandığında açılan **Aktif Pencere / Tüm Ekran Popover Menüsü**'nün eklenmesini ve Ayarlar Penceresine (`SettingsWindow.qml`) **Klavye Kısayolları (Shortcuts)** sekmesi ile KDE Kısayol entegrasyonunun kazandırılmasını kapsar.

---

## Görev 1: Ekran Seçim Araç Çubuğuna Açılır Yakalama Menüsü (Capture Mode Popover)

### Hedef
Kullanıcı araç çubuğundaki Tam Ekran butonuna (`fsBtn`) tıkladığında, butonun hemen üzerinde şık, Catppuccin temalı bir açılır menü (Popover) açılacak:
1. 🖥️ **Tüm Ekran (Full Screen)**: Tıklandığında mevcut `fullScreenRequested()` eylemini çalıştırarak tüm ekranı kırpar.
2. 🪟 **Aktif Pencere (Active Window)**: Tıklandığı anda `activeWindowRequested()` sinyalini yayar; seçim katmanı temizlenir, KWin ekran kenarları geri yüklenir ve `shell.qml` üzerindeki `captureDirect(true)` çağrılarak aktif pencere gecikmesiz çekilir.
Dışarıya tıklandığında veya Escape'e basıldığında menü kapanır.

### Değişecek Dosyalar
- `modules/screenshot/regionSelector/OptionsToolbar.qml`: Popover menüsü, buton sinyalleri (`activeWindowRequested`).
- `modules/screenshot/regionSelector/RegionSelection.qml`: `onActiveWindowRequested` sinyal yönlendirmesi.
- `modules/screenshot/regionSelector/RegionSelector.qml`: `activeWindowRequested` sinyali ve temizlik.
- `shell.qml`: `selector.onActiveWindowRequested` -> `root.captureDirect(true)` bağlantısı.
- `tests/test_toolbar.sh`: Popover yapısı ve sinyal testleri.

---

## Görev 2: Ayarlar Penceresine Klavye Kısayolları Sekmesi (Shortcuts Tab)

### Hedef
`SettingsWindow.qml` içerisine 5. sekme olarak **"Kısayollar" (Shortcuts)** eklenir:
1. Omnisnap'in 4 temel eylemi listelenir:
   - 📐 **Bölge Yakalama (Region):** `Print`
   - 🖥️ **Tüm Ekran (Full Screen):** `Shift + Print`
   - 🪟 **Aktif Pencere (Active Window):** `Meta + Print`
   - ⚙️ **Ayarlar Penceresi (Settings):** `Meta + Shift + Print` (veya `omnisnap settings`)
2. Her eylem için zarif Catppuccin rozetleri (badge) ile tuş kombinasyonları gösterilir.
3. **KDE Plasma 6 Entegrasyonu**: "KDE Kısayollarında Düzenle" butonu eklenir; tıklandığında `kcmshell6 kcm_keys` çalıştırılarak doğrudan KDE Sistem Ayarları Kısayollar modülü açılır.
4. `tests/test_settings_syntax.sh` güncellenerek 5 sekme ve kısayol bileşenlerinin doğrulanması sağlanır.

---

## Görev 3: Dokümantasyon ve Yaşayan Mimari Güncellemesi (Living Architecture)

### Hedef
- `docs/omnisnap-wiki/ui-components/floating-toolbar.md`: Yeni popover menü mimarisi.
- `docs/omnisnap-wiki/core-engine/settings-and-configuration.md`: Kısayol yönetim sekmesi.
- `docs/omnisnap-wiki/integration/desktop-and-shortcuts.md`: `Meta+Print` ve KDE Sistem Entegrasyonu.
- `docs/omnisnap-wiki/log.md`: İşlem günlüğü append-only kaydı.
- `tests/run-tests.sh` ile tüm test süitinin hatasız çalıştığının teyidi.
