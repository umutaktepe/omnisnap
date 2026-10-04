# Yapılandırma ve Ayarlar Sistemi (Settings & Configuration)

Omnisnap Yapılandırma ve Ayarlar Sistemi, uygulamanın tüm çalışma parametrelerini (kayıt dizini, dosya biçimi, çözünürlük limitleri, pano/dosya davranışları, kılavuzlar ve KWin kenar engellemesi) kalıcı olarak saklayan, çalışma zamanında reaktif olarak güncelleyen ve kullanıcıya modern bir grafik arayüz sunan çekirdek altyapıdır.

Mimari kararın teknik gerekçeleri için bkz: [[adr-006-settings-management-and-resolution-limits]].

---

## 📁 Dosya Konumu ve Depolama Formatı

Yapılandırma verileri XDG Base Directory Spesifikasyonuna tam uyumlu olarak JSON formatında saklanır:

- **Dizin**: `$XDG_CONFIG_HOME/omnisnap` (varsayılan: `~/.config/omnisnap`)
- **Dosya**: `config.json`

Örnek `config.json` içeriği:
```json
{
  "maxResolution": "1920x1080>",
  "saveDirectory": "~/Pictures/Screenshots",
  "fileFormat": "png",
  "imageQuality": 90,
  "copyToClipboard": true,
  "saveToFile": true,
  "showGuides": true,
  "inhibitScreenEdges": true,
  "defaultAction": "copy",
  "ocrLanguages": "",
  "shutterSound": false
}
```

---

## ⚙️ Çekirdek Yapılandırma Singleton'ı: `Config.qml`

`modules/config/Config.qml` dosyası bir `pragma Singleton` nesnesidir. Uygulamanın herhangi bir yerinden `import "../config"` veya `import "modules/config"` ile doğrudan erişilebilir.

### 1. Özellikler ve Varsayılan Değerler

| Özellik Adı | Tip | Varsayılan Değer | Açıklama |
|---|---|---|---|
| `maxResolution` | `string` | `""` | Maksimum çözünürlük sınırı. Boş string sınırsız demektir. Örn: `"1920x1080>"`. |
| `saveDirectory` | `string` | `"~/Pictures/Screenshots"` | Ekran görüntülerinin kaydedileceği ana dizin. `~` karakteri `$HOME` dizinine çözümlenir. |
| `fileFormat` | `string` | `"png"` | Çıktı dosya uzantısı (`png`, `jpg`, `webp`). |
| `imageQuality` | `int` | `90` | Sıkıştırma/kalite parametresi (1 - 100). |
| `copyToClipboard` | `bool` | `true` | Çekim sonrası kırpılan görselin Wayland panosuna kopyalanıp kopyalanmayacağı. |
| `saveToFile` | `bool` | `true` | Çekim sonrası görselin diske dosya olarak yazılıp yazılmayacağı. |
| `showGuides` | `bool` | `true` | Seçim esnasında karartma çerçevesi, artı çizgiler ve boyut etiketinin gösterimi. |
| `inhibitScreenEdges` | `bool` | `true` | Seçim esnasında KWin sıcak köşelerinin ve kenar hareketlerinin geçici olarak maskelenmesi. |
| `defaultAction` | `string` | `"copy"` | Araç çubuğunda ve hızlı çekimde varsayılan eylem (`copy`, `edit`, `search`, `ocr`). |
| `ocrLanguages` | `string` | `""` | OCR motoruna iletilecek diller. Boş bırakıldığında sistemde kurulu tüm diller otomatik tespit edilir. |
| `shutterSound` | `bool` | `false` | Çekim yapıldığında deklanşör ses efektinin çalınması. |
| `shortcutRegion` | `string` | `"Print"` | Bölge seçimi yakalama kısayolu. |
| `shortcutWindow` | `string` | `"Meta+Print"` | Aktif pencere yakalama kısayolu. |
| `shortcutFullScreen` | `string` | `"Shift+Print"` | Tüm ekran yakalama kısayolu. |
| `shortcutSettings` | `string` | `"Meta+Shift+Print"` | Omnisnap ayarları açma kısayolu. |
| `loaded` | `bool` | `false` | Yapılandırma dosyasının diskten başarıyla okunup ayrıştırıldığını belirten bayrak. |

### 2. JSON Serileştirme ve Ayrıştırma

`Config.qml` çalışma zamanı durumunu serileştirmek ve dışarıdan gelen JSON verilerini modele yüklemek için iki atomik metoda sahiptir:

```javascript
function toJsonString() {
    const obj = {
        "maxResolution": root.maxResolution,
        "saveDirectory": root.saveDirectory,
        "fileFormat": root.fileFormat,
        "imageQuality": root.imageQuality,
        "copyToClipboard": root.copyToClipboard,
        "saveToFile": root.saveToFile,
        "showGuides": root.showGuides,
        "inhibitScreenEdges": root.inhibitScreenEdges,
        "defaultAction": root.defaultAction,
        "ocrLanguages": root.ocrLanguages,
        "shutterSound": root.shutterSound
    };
    return JSON.stringify(obj, null, 2);
}

function applyJson(jsonStr) {
    if (!jsonStr || jsonStr.trim() === "") return;
    try {
        const data = JSON.parse(jsonStr);
        if (data.maxResolution !== undefined) root.maxResolution = data.maxResolution;
        if (data.saveDirectory !== undefined) root.saveDirectory = data.saveDirectory;
        if (data.fileFormat !== undefined) root.fileFormat = data.fileFormat;
        if (data.imageQuality !== undefined) root.imageQuality = data.imageQuality;
        if (data.copyToClipboard !== undefined) root.copyToClipboard = data.copyToClipboard;
        if (data.saveToFile !== undefined) root.saveToFile = data.saveToFile;
        if (data.showGuides !== undefined) root.showGuides = data.showGuides;
        if (data.inhibitScreenEdges !== undefined) root.inhibitScreenEdges = data.inhibitScreenEdges;
        if (data.defaultAction !== undefined) root.defaultAction = data.defaultAction;
        if (data.ocrLanguages !== undefined) root.ocrLanguages = data.ocrLanguages;
        if (data.shutterSound !== undefined) root.shutterSound = data.shutterSound;
    } catch (e) {
        console.warn("[Omnisnap Config] Failed to parse config.json:", e);
    }
}
```

### 3. Asenkron Disk Erişimi (Quickshell I/O Entegrasyonu)

- **Okuma (`load`)**: Bileşen yüklendiğinde (`Component.onCompleted`) Quickshell'in `Quickshell.Io.Process` nesnesi ve `StdioCollector` aracılığıyla diskteki dosya asenkron olarak okunur. Dosya yoksa `{}` dönülerek varsayılan değerler korunur.
- **Yazma (`save`)**: Yapılandırma kaydedilirken `Quickshell.execDetached` kullanılarak arka planda kabuk komutu tetiklenir:
  ```javascript
  Quickshell.execDetached([
      "bash", "-c",
      `mkdir -p '${safeDir}' && printf '%s\n' '${jsonContent}' > '${safePath}'`
  ]);
  ```
  Tüm dosya yolları ve JSON içeriği tek tırnak (`'`) karakterlerine karşı `replace(/'/g, "'\\''")` ile kaçırılarak (shell escape) komut enjeksiyonu riskleri engellenmiştir.

---

## 📐 En-Boy Oranını Koruyan Çözünürlük Sınırlandırması

Özellikle yüksek çözünürlüklü (4K UHD, 5K, ultrawide) monitörlerde alınan ekran görüntüleri megabaytlarca yer kaplayabilir veya mesajlaşma uygulamalarında aktarımı yavaşlatabilir.

Omnisnap, ImageMagick'in şartlı boyutlandırma bayrağını (`>`) kullanarak bu sorunu çözer:
- **Boru Hattı Entegrasyonu**: `modules/screenshot/ScreenshotAction.qml` içerisindeki `getScript()` fonksiyonunda:
  ```javascript
  const activeMaxRes = (maxResOverride !== null && maxResOverride !== undefined) ? maxResOverride : Config.maxResolution;
  const resizeArg = (activeMaxRes && activeMaxRes.trim() !== "") ? ` -resize '${escapeShellStr(activeMaxRes.trim())}'` : "";
  const cropBase = `magick '${escapeShellStr(screenshotPath)}' -crop ${rw}x${rh}+${rx}+${ry} +repage${resizeArg}`;
  ```
- **ImageMagick Mantığı**:
  - `1920x1080>` sözdizimi: Eğer kırpılan görselin genişliği 1920 pikselden VEYA yüksekliği 1080 pikselden büyükse, en-boy oranını (aspect ratio) koruyarak bu kutunun içine sığacak şekilde küçültür.
  - Eğer kırpılan görsel belirtilen sınırdan küçükse (örneğin 400x300 piksellik bir buton veya simge), hiçbir işlem yapmaz (asla büyütmez/upscale etmez), orijinal pikselleri korur.

---

## 🖥️ Kullanıcı Arayüzü: `SettingsWindow.qml`

`modules/settings/SettingsWindow.qml`, Quickshell'in `FloatingWindow` API'si kullanılarak geliştirilmiş modern bir XDG toplevel penceresidir.

### Temel Özellikler:
1. **Pencere Boyutları ve Yönetimi**:
   - Varsayılan boyut: `740x560`, asgari boyut: `680x500`.
   - Sekme çubuğu yatay `Flickable` kapsayıcısına alınarak sekme taşmaları ve sağ kenardan kesilme sorunları tamamen önlenmiştir.
   - Masaüstünde serbestçe sürüklenebilir ve yeniden boyutlandırılabilir.
   - Esc tuşu, pencere içi kapat butonu veya KDE Plasma başlık çubuğu kapatma butonu ('X') / Alt+F4 (`onClosed`) ile kapatıldığında oneshot modunda süreci zombi bırakmadan temizce sonlandırır (`kill -TERM`).
2. **Sekmeli Gezinme**:
   - **Görüntü ve Çözünürlük**: Dosya biçimi (`png`, `jpg`, `webp`), görüntü kalitesi kaydırıcısı (slider), maksimum çözünürlük hap butonları (Sınırsız, 4K, 1440p, 1080p, 720p) veya özel geometri girişi.
   - **Kayıt ve Pano**: Ekran görüntüsü kayıt klasörü yolu seçimi, panoya kopyalama ve dosyaya kaydetme anahtarları.
   - **Arayüz ve Seçim**: Seçim esnasında görsel kılavuzlar (büyüteç, boyut etiketi, artı çizgisi), KWin sıcak kenar engelleme anahtarı ve deklanşör sesi efekti.
   - **Klavye Kısayolları**: Omnisnap'in tüm yakalama eylemleri için (Bölge Seçimi, Aktif Pencere, Tüm Ekran, Ayarlar) doğrudan arayüz içinden düzenlenebilir metin alanları, "Uygula" butonları, tek tıkla arka planda KDE'ye yazan "KDE'ye Tanımla & Eşitle" butonu ve harici KDE Plasma Kısayol Düzenleyicisini (`kcmshell6 kcm_keys`) açma seçeneği.
   - **OCR ve Metin**: Tesseract OCR dil kodları (`tur`, `eng`, `tur+eng`) ve popüler dil hapları.
3. **Kalıcılık ve Geribildirim**:
   - "Kaydet" butonuna tıklandığında `Config.save()` çağrılır ve 2.5 saniyelik yeşil başarı bilgi çubuğu (`saveSuccess = true`) gösterilir.
   - Kısayol senkronizasyonunda "KDE Plasma'ya (kglobalshortcutsrc) başarıyla yazıldı" onay rozeti (`shortcutSyncSuccess = true`) görüntülenir.
   - "Varsayılanlara Sıfırla" butonu tüm ayarları standart fabrika ayarlarına döndürür.

---

## 🔗 Sistem Entegrasyon Noktaları

### 1. `shell.qml` Entegrasyonu
- `SettingsWindow` nesnesi `shell.qml` kök ağacında tanımlıdır.
- `IpcHandler { target: "region" }` içine `settings()` metodu eklenmiştir:
  ```qml
  function settings() {
      settingsWindow.show();
  }
  ```
- Araç çubuğunda (`RegionSelector.qml`) ayarlar butonuna basıldığında `onOpenSettingsRequested` sinyali dinlenerek pencere açılır.
- Ortam değişkeni `OMNISNAP_INITIAL_ACTION="settings"` olduğunda pencere bağımsız modda (`settingsWindow.isStandalone = true`) açılır.

### 2. `bin/omnisnap` CLI Entegrasyonu
- Komutlar: `omnisnap settings`, `omnisnap -c`, `omnisnap --settings`, `omnisnap config`.
- Hibrit yaşam döngüsü kontrolü:
  - Arka plan servisi (daemon) çalışıyorsa: `_call_ipc "settings"` ile mevcut sürece pencereyi açma talimatı verilir (0ms gecikme).
  - Arka plan servisi çalışmıyorsa: `_launch_oneshot "settings"` ile tek seferlik Quickshell süreci başlatılır; pencere kapatıldığında `Qt.quit()` ile süreç sonlanır.

### 3. `OptionsToolbar.qml` Entegrasyonu
- Araç çubuğunun sağ tarafına yerleştirilen dişli simgesi (`settings` ikonu) doğrudan `RegionSelector` üzerindeki `openSettingsRequested` sinyalini tetikler.

---

## 🧪 Test ve Doğrulama

Ayarlar sistemi aşağıdaki otomatik test süitleri ile korunmaktadır:
- `tests/test_config.sh`: `Config.qml` JSON serileştirme, `applyJson`, `$XDG_CONFIG_HOME` çözünürlüğü ve kabuk kaçış doğrulamaları.
- `tests/test_settings_syntax.sh`: `SettingsWindow.qml` ve `Config.qml` bileşenlerinin `qmllint` Qt 6 sözdizimi ve import geçerlilik kontrolleri.
- `tests/test_action_pipeline.sh`: `maxResolution` geometri parametresinin ImageMagick `-resize` komut zincirine en-boy koruma bayrağıyla (`>`) hatasız yansıdığının testi.
- `tests/test_cli.sh`: `omnisnap settings` ve `-c` komut satırı bayraklarının test edilmesi.

---

## İlişkili Dokümanlar
- Mimari Karar Kaydı: [[adr-006-settings-management-and-resolution-limits]]
- Eylem Orkestrasyonu: [[action-orchestration]]
- Görüntü Kırpma Boru Hattı: [[image-crop-pipeline]]
- Araç Çubuğu Bileşeni: [[floating-toolbar]]
- Komut Satırı Arayüzü: [[cli-interface]]
- Tasarım Sistemi: [[design-system]]
- Süreç Yaşam Döngüsü: [[process-lifecycle]]
