# ADR-006: Yapılandırma Yönetimi, Çözünürlük Limitleri ve Ayarlar Arayüzü

- **Durum**: Kabul Edildi
- **Tarih**: 2026-09-28
- **İlgili Bileşenler**: [[settings-and-configuration]], [[action-orchestration]], [[floating-toolbar]], [[cli-interface]], [[design-system]], [[image-crop-pipeline]]

## Bağlam (Context)
Omnisnap ilk tasarımında varsayılan parametreler (kayıt dizini, dosya formatı, panoya kopyalama, görsel kılavuzlar ve ekran kenarı maskelemesi) kaynak kod içine sabitlenmiş (hardcoded) durumdaydı. Kullanıcıların çekim alışkanlıklarını özelleştirebilmesi, özellikle 4K ve ultra geniş (ultrawide) monitörlerde yüksek çözünürlüklü ekran alıntılarının dosya boyutunu veya panoda kapladığı alanı kontrol altında tutabilmesi için esnek bir ayarlar altyapısına ihtiyaç duyuldu.

Bu bağlamda üç temel mühendislik problemi çözülmelidir:
1. **Yapılandırma Kalıcılığı**: Ayarların sistemde nasıl saklanacağı ve QML / CLI katmanları tarafından nasıl okunup yazılacağı.
2. **Çözünürlük Sınırlandırması**: Ekran görüntüsü en-boy oranını (aspect ratio) bozmadan ve küçük kırpmaları yapay olarak büyütüp (upscale) piksellendirmeden maksimum piksel sınırının uygulanması.
3. **Kullanıcı Arayüzü Mimarisi**: Ayarlar penceresinin Wayland LayerShell katmanından bağımsız, masaüstüyle uyumlu ve hem CLI hem de araç çubuğundan çağrılabilir biçimde sunulması.

## Değerlendirilen Alternatifler (Alternatives Considered)

### 1. Yapılandırma Formatı: Qt QSettings / KConfig vs. XDG JSON
- **Qt QSettings (INI) / KDE KConfig**:
  - *Avantaj*: KDE ekosisteminde yaygın kullanım, otomatik senkronizasyon.
  - *Dezavantaj*: C++ eklentisi veya harici `kreadconfig6`/`kwriteconfig6` çağrıları gerektirir. Quickshell saf QML ortamında doğrudan yerel nesne eşlemesi zordur; harici CLI betiklerinin INI ayrıştırması karmaşıktır.
- **XDG JSON (`~/.config/omnisnap/config.json`)**:
  - *Avantaj*: XDG Base Directory Spesifikasyonu ile tam uyum (`$XDG_CONFIG_HOME/omnisnap/config.json`). QML/JavaScript çalışma zamanında yerel `JSON.parse` ve `JSON.stringify` ile sıfır bağımlılıkla işlenir. İnsan tarafından elle düzenlenebilir ve `jq` veya bash betikleriyle kolayca doğrulanabilir.
  - *Dezavantaj*: Dosya yazma işlemlerinin kabuk üzerinden (`Quickshell.execDetached`) atomik ve tırnak işaretlerinden kaçırılarak (shell-escaping) yürütülmesi gerekir.

### 2. Çözünürlük Sınırlandırma Yöntemi: Sabit Piksel Ölçekleme vs. ImageMagick Geometri Bayrağı
- **Sabit Ölçekleme (`-resize WxH!`) veya Yüzdelik Küçültme (`-resize 50%`)**:
  - *Avantaj*: Basit matematik.
  - *Dezavantaj*: `!` bayrağı en-boy oranını bozar ve görüntüyü sündürür. Yüzdelik küçültme ise küçük seçimleri de küçülterek okunamaz hale getirir.
- **ImageMagick Şartlı Boyutlandırma (`-resize 'WIDTHxHEIGHT>'`)**:
  - *Avantaj*: `>` geometri bayrağı ImageMagick'e "yalnızca görselin genişliği veya yüksekliği belirtilen sınırdan büyükse küçült, küçükse kesinlikle dokunma" talimatı verir. En-boy oranı kusursuz biçimde korunur, yukarı ölçekleme (upscaling) ve bulanıklaşma tamamen engellenir.
  - *Dezavantaj*: Kabuk kaçışında tırnaklama (`'`) ve `>` karakterinin bash yönlendirmesiyle karışmaması için sıkı tırnak içine alma gerekir.

### 3. Ayarlar Arayüzü: Harici Qt/GTK Penceresi vs. Quickshell `FloatingWindow`
- **Harici Python/Zenith/KDialog Penceresi**:
  - *Avantaj*: Hızlı prototipleme.
  - *Dezavantaj*: Ayrı bir işlem başlatma gecikmesi, görsel tutarsızlık, Omnisnap tema sistemiyle uyumsuzluk.
- **Quickshell `FloatingWindow`**:
  - *Avantaj*: Quickshell'in standart Wayland XDG toplevel pencere API'sidir. LayerShell tam ekran kısıtlamasından bağımsız olarak normal bir uygulama penceresi gibi davranır (taşınabilir, yeniden boyutlandırılabilir, kapatılabilir). Omnisnap'in `Theme.qml` ve atomik UI bileşenlerini doğrudan paylaşır.
  - *Dezavantaj*: Daemon modunda arka planda hazır bekletilmeli, oneshot modunda ise `isStandalone` bayrağı ile pencere kapandığında `Qt.quit()` çağrılmalıdır.

## Karar (Decision)

1. **XDG JSON Depolama Modeli**:
   - Yapılandırma `$XDG_CONFIG_HOME/omnisnap/config.json` (varsayılan: `~/.config/omnisnap/config.json`) altında JSON formatında tutulur.
   - `modules/config/Config.qml` tekil (Singleton) nesnesi sistem ayağa kalkarken `cat` ile asenkron okunur (`Quickshell.Io.Process` + `StdioCollector`) ve değişiklikler `printf` ile diske atomik yazılır.

2. **ImageMagick Geometri Bayrağı ile Çözünürlük Kısıtlama**:
   - `modules/screenshot/ScreenshotAction.qml` içerisindeki `cropBase` komut zincirine şartlı olarak ` -resize '${activeMaxRes.trim()}'` parametresi eklenir.
   - Yapılandırmada `1920x1080>`, `2560x1440>`, `3840x2160>` gibi standart ön tanımlar veya özel değerler desteklenir; boş bırakıldığında kısıtlama uygulanmaz (sınırsız).

3. **Quickshell `FloatingWindow` Tabanlı Ayrık Ayarlar Penceresi**:
   - `modules/settings/SettingsWindow.qml` bileşeni `FloatingWindow` olarak geliştirildi.
   - Ekran alıntısı araç çubuğundaki (`OptionsToolbar.qml`) dişli butonuna tıklandığında veya CLI üzerinden `omnisnap settings` / `omnisnap -c` çalıştırıldığında anında açılır.
   - Sekmeli yapıda (Genel, Çözünürlük & Biçim, Gelişmiş) tüm ayarlar interaktif kontrol edilir ve görsel başarı geribildirimi sunulur.

## Sonuçlar ve Ödünleşimler (Consequences & Trade-offs)
- **Kusursuz En-Boy Oranı ve Sıfır Bozulma**: 4K veya ultrawide ekranlarda alınan tam ekran görüntüler hedef çözünürlüğe (örn. 1080p) orantılı olarak indirilirken, küçük buton veya metin kırpmaları hiçbir kalite kaybı yaşamadan orijinal pikselleriyle saklanır.
- **Hafif ve Bağımsız Yapı**: Ek hiçbir kütüphane veya C++ bağımlılığı eklenmeden saf QML/JS ve ImageMagick boru hattıyla tüm yapılandırma ve görsel limitler çözülmüştür.
- **Esnek Yaşam Döngüsü**: Ayarlar penceresi hem arka plan servisi çalışırken IPC üzerinden saniyenin altında açılabilir, hem de servis kapalıyken tekil bir bağımsız pencere (`_launch_oneshot "settings"`) olarak başlatılabilir.

## İlişkili Dokümanlar
- Teknik Dokümantasyon: [[settings-and-configuration]]
- Eylem Orkestrasyonu: [[action-orchestration]]
- Görüntü Kırpma Boru Hattı: [[image-crop-pipeline]]
- Araç Çubuğu Bileşeni: [[floating-toolbar]]
- Komut Satırı Arayüzü: [[cli-interface]]
- Tasarım Sistemi ve Renkler: [[design-system]]
