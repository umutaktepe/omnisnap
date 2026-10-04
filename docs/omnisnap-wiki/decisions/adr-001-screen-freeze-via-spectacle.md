# ADR-001: Spectacle ile Ekran Dondurma (Screen Freeze) Mimarisi

- **Durum**: Kabul Edildi
- **Tarih**: 2026-09-28
- **İlgili Bileşenler**: [[screen-freeze-engine]], [[layershell-overlay]], [[system-overview]]

## Bağlam (Context)
Wayland görüntü sunucusu protokolü (özellikle KDE Plasma 6 KWin bileşeni), X11'deki gibi uygulamaların rastgele ekran piksellerini global olarak doğrudan okumasına izin vermez. Ekran görüntüsü alma sürecinde kullanıcının gördüğü kareyi anında "dondurmak" (screen freeze) ve üzerinde piksel kırpma yapılabilmesi için yetkili bir yakalama katmanına ihtiyaç vardır.

Gereksinimler:
1. Ekran yakalamada pencerelerin hareketini veya animasyonları o anda sıfır gecikmeyle sabitlemek.
2. KDE Plasma 6 üzerinde root yetkisi veya KWin çekirdeğine yama yapmadan çalışmak.
3. Çoklu monitör ortamında her ekranın bağımsız karesini eşzamanlı elde edebilmek.

## Değerlendirilen Alternatifler (Alternatives Considered)

### 1. `grim` (Wayland Generic Capture)
- **Avantaj**: Hızlı ve hafif bir CLI aracı.
- **Dezavantaj**: `wlr-screencopy-unstable-v1` protokolünü kullanır. KDE Plasma 6 / KWin bu protokolü yerel olarak desteklemez, bu nedenle KDE ortamında çalışmaz.

### 2. KWin DBus Screencast / Portal API
- **Avantaj**: KDE resmi Wayland portal standardı.
- **Dezavantaj**: PipeWire akışı kurmayı, DBus üzerinden izin diyaloglarını ve oturum müzakeresini gerektirir. Anlık bir ekran karesi almak için 300-800ms arası başlatma gecikmesine (overhead) yol açar.

### 3. `spectacle -b -n -m` (KDE Background Capture)
- **Avantaj**: KDE Plasma'nın dahili, ayrıcalıklı ve donanım hızlandırmalı ekran yakalama motorunu arka planda GUI açmadan (`-b -n`) doğrudan çağırır. Her monitörü (`-m`) ayrı dosyaya kaydedebilir.
- **Dezavantaj**: Sistemde `spectacle` paketinin kurulu olmasını gerektirir.

## Karar (Decision)
[[screen-freeze-engine]] aşamasında `TempScreenshotProcess.qml` vasıtasıyla `spectacle -b -n -m -o [yol]` komutunun çalıştırılmasına karar verildi.

Bu mekanizma tetiklendiğinde:
1. `spectacle` arka planda ekranın donanım tamponunu anında diske (`/tmp` veya `$XDG_RUNTIME_DIR/omnisnap`) yazar.
2. [[layershell-overlay]] oluşturulduğunda bu kaydedilen dosya bir `Image` bileşenine atanarak tam ekran örtüsü olarak render edilir.
3. Kullanıcı seçim yaparken ekranın orijinal içeriği pikselleriyle sabit kalır.

## Sonuçlar ve Ödünleşimler (Consequences & Trade-offs)
- **Pozitif**: KWin yetkilendirme katmanını sorunsuz aşar, ekran dondurma hissi akıcıdır, KDE Plasma 6 ile %100 uyumludur.
- **Negatif**: `spectacle` bağımlılığı zorunludur.
- **Risk Yönetimi**: [[testing-harness]] içerisinde `spectacle` parametrelerinin doğruluğu ve çıktı dosyalarının varlığı test suitleri ile denetlenmektedir.
