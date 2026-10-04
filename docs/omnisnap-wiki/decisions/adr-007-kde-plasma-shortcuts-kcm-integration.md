# ADR-007: KDE Plasma 6 KCM Keys ve Standart X-KDE-Shortcuts Entegrasyonu

- **Durum**: Kabul Edildi
- **Tarih**: 2026-10-05
- **İlgili Bileşenler**: [[desktop-and-shortcuts]], [[cli-interface]], [[settings-and-configuration]], [[installation-and-packaging]], [[system-overview]], [[execution-lifecycles]]

## Bağlam (Context)
Wayland ve KDE Plasma 6 mimarisinde genel (global) klavye kısayollarının yönetimi, geleneksel X11 `XGrabKey` yöntemlerinden farklı olarak KWin besteleme katmanına ve `KGlobalAccel` arka plan servisine devredilmiştir. Kullanıcıların Spectacle yerine Omnisnap'i birincil ekran görüntüsü yakalama aracı olarak sorunsuz benimseyebilmesi için sistem düzeyinde sıfır sürtünmeli (zero-friction) bir geçiş ve KDE Sistem Ayarları Kısayollar modülü (`kcmshell6 kcm_keys`) ile kusursuz bir entegrasyon zorunludur.

Bu bağlamda çözülmesi gereken üç temel mühendislik problemi ortaya çıkmıştır:
1. **KCM Keys Kullanıcı Arayüzü Uyumluluğu**: Omnisnap kısayollarının KDE Sistem Ayarları içerisinde rasgele bir "Özel Kısayol (Custom Shortcut)" kabuk komutu olarak değil; Spectacle gibi KDE'nin yerli bileşenleriyle aynı hiyerarşide, "Uygulamalar (Applications)" kategorisi altında Omnisnap simgesi ve eylemleriyle birinci sınıf bir vatandaş olarak listelenmesi.
2. **Klavye Çakışmalarının Önlenmesi ve KGlobalAccel Senkronizasyonu**: KDE Plasma 6'da `Print`, `Meta+Print`, `Shift+Print` tuş kombinasyonları varsayılan olarak Spectacle'a (`org.kde.spectacle.desktop`) tahsis edilmiştir. Omnisnap varsayılan tuşları devralırken hem Spectacle çakışmalarını zarifçe devre dışı bırakmalı (`none`), hem de KGlobalAccel önbelleğine oturumu yeniden başlatmaya gerek kalmaksızın dinamik bildirim (`--notify`) gönderebilmelidir.
3. **İlk Çalıştırmada Sıfır Müdahale (Zero-Config First Launch)**: Kullanıcının kurulumdan sonra terminale girip manuel bir betik çalıştırmasını veya Sistem Ayarları'nda tek tek eylem araması gerekliliğini ortadan kaldıran, ilk çalıştırmada (`omnisnap`) sessiz ve otomatik bir öz-kayıt (self-registration) mekanizmasının kurulması.

## Değerlendirilen Alternatifler (Alternatives Considered)

### 1. Çalışma Zamanında Dinamik DBus / Portal KGlobalAccel Kaydı
- *Yöntem*: Quickshell QML veya C++ başlatılırken `org.kde.KGlobalAccel` DBus arayüzüne bağlanarak kısayolları çalışma zamanında dinamik olarak kaydetmek.
- *Avantaj*: Uygulama içinden dinamik kontrol.
- *Dezavantaj*: Omnisnap hem tek atımlık (oneshot) hem de arka plan servisi (daemon) hibrit mimarisiyle çalışır ([[adr-002-dual-lifecycle-oneshot-and-daemon]]). Oneshot modunda işlem kapandığı anda dinamik DBus kısayollarının KWin tarafından düşürülmesi veya askıda kalması riski vardır. Ayrıca KDE Sistem Ayarları (`kcm_keys`) modülünde kalıcı bir `.desktop` eylem hiyerarşisi oluşturamaz ve "Varsayılana Sıfırla (Reset to Defaults)" desteği sunamaz.

### 2. Yalnızca Kurulum Betiği (`install.sh`) ile Statik Dosya Yazımı
- *Yöntem*: Sadece `install.sh` yürütüldüğünde `~/.config/kglobalshortcutsrc` dosyasına statik girdiler eklemek.
- *Avantaj*: Basit kurgu.
- *Dezavantaj*: Kullanıcı projeyi doğrudan yerel kopyasından çalıştırdığında veya `install.sh` öncesinde CLI üzerinden başlattığında kısayollar tanımsız kalır. `.desktop` dosyasında standart deklarasyon olmadığı takdirde KCM Keys modülü uygulamanın fabrika ayarı kısayollarını tespit edemez.

### 3. Standart `X-KDE-Shortcuts` Deklarasyonu + `bin/omnisnap-shortcuts` Otomasyonu + İlk Çalıştırmada Sessiz Doğrulama (Seçilen Yöntem)
- *Yöntem*: `omnisnap.desktop` spesifikasyonunda hem kök uygulama hem de her `[Desktop Action ...]` girdisinde Freedesktop/KDE standardı olan `X-KDE-Shortcuts` direktiflerini bildirmek; bağımsız `bin/omnisnap-shortcuts` aracıyla `kglobalshortcutsrc` dosyasında `[services][omnisnap.desktop]` grubu altında `_k_friendly_name="Omnisnap"` ve eylem eşleştirmelerini yönetmek; çakışan Spectacle eylemlerini `none` yaparak KGlobalAccel'e anında bildirim iletmek; ve `bin/omnisnap` giriş noktasında ilk çalıştırmayı sessizce kontrol eden `_ensure_desktop_and_shortcuts` kancasını çalıştırmak.
- *Avantaj*:
  - KDE Sistem Ayarları Kısayollar modülünde Omnisnap doğrudan "Uygulamalar" altında tüm eylemleri ve simgeleriyle eksiksiz listelenir.
  - KDE'nin yerleşik "Varsayılana Sıfırla" butonu, `.desktop` dosyasındaki `X-KDE-Shortcuts` değerlerini referans alarak kısayolları otomatik geri yükler.
  - Kullanıcı ister terminalden `omnisnap`, ister uygulama menüsünden başlatsın; ilk çalıştırmada masaüstü dosyası ve kısayollar arka planda şeffaf biçimde kurulur.
  - Hem `kwriteconfig6` hem de Python 3 `configparser` fallback mimarisi ile her türlü Linux/KDE ortamında güvenilir çalışır.
- *Dezavantaj*: `kglobalshortcutsrc` dosyasının `[services][omnisnap.desktop]` biçimindeki çift gruplu INI sözdizimi ve büyük/küçük harf koruma gereksinimi nedeniyle ayrıştırma katmanında özen gerektirir.

## Karar (Decision)

1. **`omnisnap.desktop` İçinde Standart `X-KDE-Shortcuts` Direktifleri**:
   - Kök `[Desktop Entry]` seviyesinde: `X-KDE-Shortcuts=Print` (Omnisnap varsayılan başlatma).
   - `[Desktop Action Region]`: `X-KDE-Shortcuts=Print` (Bölge seçimi).
   - `[Desktop Action Window]`: `X-KDE-Shortcuts=Meta+Print` (Aktif pencere yakalama).
   - `[Desktop Action FullScreen]`: `X-KDE-Shortcuts=Shift+Print` (Tam ekran yakalama).
   - `[Desktop Action Settings]`: `X-KDE-Shortcuts=Meta+Shift+Print` (Ayarlar arayüzü).

2. **`bin/omnisnap-shortcuts` Otomasyon Motoru**:
   - `_write_kconfig` ve `_read_kconfig` soyutlamaları geliştirildi. `kwriteconfig6` mevcutsa `--notify` bayrağı ile KGlobalAccel anında tetiklenir; mevcut değilse Python 3'ün `RawConfigParser(optionxform=str)` motoru ile INI anahtar büyük/küçük harf duyarlılığı (`optionxform`) ve `group1][group2` KDE hiyerarşisi korunarak yazma yapılır.
   - `apply-defaults` komutu:
     - `_k_friendly_name="Omnisnap"` tanımlayarak KCM listesinde estetik görünüm sağlar.
     - `_launch`, `Region`, `Window`, `FullScreen` ve `Settings` eylemlerini `Shortcut,DefaultShortcut,Description` üçlüsü formatında `kglobalshortcutsrc` dosyasına işler.
     - Çakışan `org.kde.spectacle.desktop` girdilerini (`RectangularRegionScreenShot`, `ActiveWindowScreenShot`, `FullScreenScreenShot`) devre dışı bırakır (`none`).

3. **İlk Çalıştırmada Sessiz Doğrulama (`_ensure_desktop_and_shortcuts`)**:
   - `bin/omnisnap` kabuk başlatıcısına eklenen kanca; `$XDG_DATA_HOME/applications/omnisnap.desktop` dosyasının mevcudiyetini ve `X-KDE-Shortcuts` yönergesini içerip içermediğini kontrol eder.
   - Dosya yoksa veya eski bir sürümden kalmaysa, arka planda sessizce `omnisnap-shortcuts apply-defaults` komutunu çalıştırarak sıfır kullanıcı müdahalesiyle sistem seviyesinde entegrasyonu tamamlar.

4. **Uygulama İçi (In-App) Yönetim ve KCM Köprüsü**:
   - `modules/settings/SettingsWindow.qml` içerisindeki "Klavye Kısayolları" sekmesine doğrudan `kcmshell6 kcm_keys` başlatan buton yerleştirildi.
   - Kullanıcı dilerse grafik arayüzdeki "KDE'ye Tanımla & Eşitle" butonuyla (`Config.applyKdeShortcuts()`) tüm ayarları tek tıkla yenileyebilir.

## Sonuçlar ve Ödünleşimler (Consequences & Trade-offs)

- **Spectacle ile Tam Eşdeğer Yerli Deneyim**: Kullanıcı KDE Kısayollar menüsüne girdiğinde Omnisnap'i yabancı bir betik gibi değil, sistemin doğal ekran alıntısı aracı olarak görür ve yönetir.
- **Sıfır Kurulum Engeli (Out-of-the-Box Functionality)**: Kullanıcı Omnisnap'i kurduğu veya ilk kez çalıştırdığı anda Print tuşuna bastığında Omnisnap tuvali açılır; Spectacle ile tuş çakışması yaşanmaz.
- **Sistem Standartlarına Saygı**: `X-KDE-Shortcuts` kullanımı sayesinde KDE Plasma'nın "Varsayılanlara Dön" özelliği Omnisnap eylemlerini bozmaz, doğru tuş kombinasyonlarını yeniden oluşturur.
- **Düşük Bağımlılık Maliyeti**: Harici bir C++ arka plan servisi yerine KDE'nin yerel `kwriteconfig6` aracı ve Python 3 standart kütüphanesi kullanılarak ek sistem bağımlılığı yaratılmamıştır.

## İlişkili Dokümanlar
- Masaüstü Entegrasyonu ve Kısayollar: [[desktop-and-shortcuts]]
- Komut Satırı Arayüzü: [[cli-interface]]
- Yapılandırma ve Ayarlar: [[settings-and-configuration]]
- Kurulum ve Paketleme: [[installation-and-packaging]]
- Sistem Genel Bakışı: [[system-overview]]
- Yaşam Döngüleri: [[execution-lifecycles]]
- Test Mimarisi ve Doğrulama: [[testing-harness]]
