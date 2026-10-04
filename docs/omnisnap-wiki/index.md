# Omnisnap Yaşayan Mimari Wikisi (Living Architecture Wiki)

> **Paradigma:** Andrej Karpathy LLM Wiki / Living Architecture
> **Hedef Sistem:** Omnisnap — KDE Plasma 6 (Wayland) Bağımsız Ekran Yakalama Aracı
> **Son Güncelleme:** 2026-10-05
> **Kronolojik Kayıtlar:** [[log]]

Bu wiki, Omnisnap kod tabanının yaşayan, ilişkisel mühendislik hafızasıdır. Kitap bölümleri yerine fonksiyonel domainler, atomik wikilinkler (`[[sayfa-adi]]`), cluster topolojisi ve Mimari Karar Kayıtları (ADR) ile organize edilmiştir.

---

## 🏛️ Mimari Prensipler ve Sistem Yapısı (Architecture)
Sistemin genel tasarım ilkeleri, Wayland LayerShell katman yönetimi ve yaşam döngüleri.

- [[system-overview]]: Sistem genel bakışı, çekirdek ilkeler, bileşenler arası veri akışı ve yüksek seviyeli mimari haritası.
- [[execution-lifecycles]]: Tek atımlık (oneshot) soğuk çalıştırma ile sıfır gecikmeli arka plan servis (daemon) modlarının karşılaştırması ve IPC protokolü.
- [[multi-display-topology]]: Çoklu monitör ortamında fiziksel ekranların (`Quickshell.screens`) bağımsız örneklenmesi ve HiDPI ölçekleme normalizasyonu.

---

## ⚖️ Mimari Karar Kayıtları (Architectural Decision Records - ADR)
Kod tabanındaki kritik tasarım seçimleri, değerlendirilen alternatifler ve ödünleşimler (trade-offs).

- [[adr-001-screen-freeze-via-spectacle]]: Neden `grim` veya PipeWire portal yerine KDE'nin yerleşik `spectacle -b -n -m` motoru ile ekran dondurma tercih edildi?
- [[adr-002-dual-lifecycle-oneshot-and-daemon]]: Düşük RAM tüketimi ile sıfır başlatma gecikmesini uzlaştıran hibrit çift yaşam döngüsü seçimi.
- [[adr-003-kwin-screen-edge-inhibition]]: Seçim esnasında KWin sıcak köşelerinin ve genel bakış efektinin dinamik JSON durum maskelemesiyle engellenmesi.
- [[adr-004-multimodal-post-processing-pipeline]]: C++ eklentileri yerine modüler Unix boru hattı (`magick`, `wl-copy`, `notify-send`, `swappy`, `tesseract`, `curl`) kararı.
- [[adr-005-layershell-pointer-transparency]]: Görsel kılavuz katmanlarında `enabled: false` kullanılarak fare bırakma olaylarının kilitlenmesini önleme kararı.
- [[adr-006-settings-management-and-resolution-limits]]: XDG JSON tabanlı yapılandırma kalıcılığı, en-boy oranını koruyan ImageMagick çözünürlük kısıtlama bayrağı ve Quickshell FloatingWindow ayar penceresi seçimi.
- [[adr-007-kde-plasma-shortcuts-kcm-integration]]: KDE Plasma 6 KCM Keys, standart X-KDE-Shortcuts yönergeleri ve ilk çalıştırmada sessiz kısayol kaydı mimarisi.

---

## ⚙️ Çekirdek Motor (Core Engine)
Ekran dondurma, KWin kenar maskelemesi ve süreç sonlandırma mekanizmaları.

- [[screen-freeze-engine]]: `TempScreenshotProcess.qml` arka plan süreci, dondurulan karesinin LayerShell tuvaline yüklenmesi ve temizliği.
- [[screen-edge-inhibitor]]: `bin/omnisnap-edges` aracı, `stolen-screen-edges.json` durum dosyası, KWin DBus reconfigure ve kaza kurtarma (`recover`).
- [[process-lifecycle]]: Oneshot modunda `kill -TERM` ile temiz kapanış, zombi süreç önleme ve diskteki geçici dosyaların imhası.
- [[settings-and-configuration]]: XDG JSON yapılandırma motoru (`Config.qml`), ayarlar penceresi (`SettingsWindow.qml`), çözünürlük limitleri ve CLI/IPC entegrasyonu.

---

## 🎨 Kullanıcı Arayüzü ve Etkileşim (UI Components)
Wayland LayerShell pencereleri, fare sürükleme mekaniği, görsel kılavuzlar ve tasarım sistemi.

- [[layershell-overlay]]: `RegionSelection.qml`, `PanelWindow` LayerShell yapılandırması, `Exclusive` klavye odağı ve Esc dinleyicisi.
- [[selection-mechanics]]: Dikdörtgen sürükleme koordinatları, mikro tıklama tam ekran toleransı, sol tık vs sağ tık (Swappy) ayrımı.
- [[visual-guides]]: `RectCornersSelectionDetails.qml` karartma çerçevesi, artı hedef çizgileri, boyut etiketi ve `CursorGuide.qml` dinamik mod hapı.
- [[floating-toolbar]]: `OptionsToolbar.qml` ve `ToolbarTabBar.qml`, ekran altı yüzen hap araç çubuğu, sekme geçişleri ve tam ekran butonu.
- [[design-system]]: `Theme.qml` renk paleti, `Icon.qml`, `IconButton.qml`, `StyledText.qml` ve `Tooltip.qml` atomik bileşenleri.

---

## ⚡ Eylem ve İşleme Boru Hatları (Pipelines)
Seçilen piksel alanının kırpılması ve hedeflenen eyleme yönlendirilmesi.

- [[action-orchestration]]: `ScreenshotAction.qml` singleton yapısı, shell kaçış güvenliği, eylem enum'ları ve komut üretimi.
- [[image-crop-pipeline]]: ImageMagick `magick -crop +repage` piksel kesim formülasyonu ve koordinat tam sayı yuvarlama kuralları.
- [[clipboard-and-notifications]]: `wl-copy` ile panoya anında aktarım ve kilitlenmeyen `( ... ) &` asenkron alt kabuk masaüstü bildirimleri.
- [[annotation-swappy]]: Swappy aracına el sıkışma (hand-off), geçici dosya üzerinde çizim ve iptal güvenliği.
- [[ocr-extraction]]: Gri tonlama ve %300 büyütme ön işlemesi, sistemdeki tüm Tesseract dillerinin otomatik tespiti ve metin kopyalama.
- [[lens-visual-search]]: Uguu.se geçici görsel yüklemesi, `jq` ile URL ayrıştırma ve Google Lens tarayıcı yönlendirmesi.

---

## 🔌 Sistem Entegrasyonu ve Dağıtım (Integration)
CLI sözdizimi, KDE Plasma kısayol eşleştirmeleri, kurulum otomasyonu ve test takımı.

- [[cli-interface]]: `bin/omnisnap` komut satırı bayrakları, daemon durum sorgulama ve IPC sinyalleri.
- [[desktop-and-shortcuts]]: `omnisnap.desktop` spesifikasyonu, `bin/omnisnap-shortcuts` otomasyon motoru, KDE Plasma 6 Kısayollar menüsü entegrasyonu ve Spectacle tuş değişimi.
- [[installation-and-packaging]]: `install.sh` sembolik bağları, bağımlılık tablosu, yerel dizin kurulumu ve kaldırma adımları.
- [[testing-harness]]: `tests/` altındaki bash ve `qmllint` regresyon test suitleri, test çalıştırma yönergeleri ve izolasyon.
