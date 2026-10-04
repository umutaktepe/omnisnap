# ADR-004: Çok Modlu Son İşleme Boru Hattı (Multimodal Post-Processing Pipeline)

- **Durum**: Kabul Edildi
- **Tarih**: 2026-09-28
- **İlgili Bileşenler**: [[action-orchestration]], [[image-crop-pipeline]], [[clipboard-and-notifications]], [[annotation-swappy]], [[ocr-extraction]], [[lens-visual-search]]

## Bağlam (Context)
Modern bir ekran yakalama aracından yalnızca ham görüntü dosyası kaydetmesi beklenmez. Kullanıcılar şu dört temel eylemi anında gerçekleştirebilmelidir:
1. **Kopyalama/Kaydetme (Copy/Save)**: Dosyaya yazma, Wayland panosuna yükleme ve interaktif masaüstü bildirimi.
2. **Düzenleme (Edit)**: Çizim, oklar, bulanıklaştırma (blur) ve metin ekleme.
3. **Optik Karakter Tanıma (OCR)**: Seçilen alandaki metinleri panoya aktarma.
4. **Görsel Arama (Search)**: Seçilen görsel parçasıyla Google Lens üzerinden arama yapma.

Bu işlevleri sağlamak için harici ağır bağımlılıklar (Python OpenCV kütüphaneleri, C++ eklentileri) eklemek hem bakım yükünü hem de disk/bellek ayak izini aşırı artıracaktır.

## Değerlendirilen Alternatifler (Alternatives Considered)

### 1. Monolitik C++ / Qt Eklentisi Yazmak
- **Avantaj**: Süreç içi (in-process) bellek tamponuyla çalışma.
- **Dezavantaj**: Yüksek derleme bağımlılığı, KDE sürüm yükseltmelerinde ABI uyumsuzluğu riski, ağır kod tabanı.

### 2. Harici Python / Electron Servisi
- **Avantaj**: Hazır kütüphane zenginliği.
- **Dezavantaj**: Yavaş başlatma süreleri, Python sanal ortam yönetimi karmaşası, kaynak israfı.

### 3. Unix Felsefesine Dayalı Modüler CLI Boru Hattı
- **Avantaj**: Linux ekosisteminin en olgun araçlarını (`magick`, `wl-copy`, `notify-send`, `swappy`, `tesseract`, `curl`, `jq`) bir araya getirerek bash boru hattında birleştirmek.
- **Dezavantaj**: Shell kaçış karakterlerinin (escaping) çok dikkatli yönetilmesi ve asenkron alt süreçlerin bloke olmamasının sağlanması gerekir.

## Karar (Decision)
[[action-orchestration]] Singleton nesnesi (`ScreenshotAction.qml`) üzerinden yapılandırılan Unix boru hattı mimarisi seçildi.

1. **Görsel Kırpma**: ImageMagick `magick -crop [w]x[h]+[x]+[y] +repage` ile saf matematiksel piksel kesimi yapılır.
2. **Asenkron Bildirim**: Bildirim eylemleri (`notify-send --action="open=Open"`) bir alt kabukta arka planda `( ... ) &` olarak çalıştırılır; böylece kullanıcının bildirime tıklamasını beklemeden pano kopyalama ve arayüz kapatma anında tamamlanır.
3. **Görsel Arama**: Uguu API (`https://uguu.se/upload`) üzerinden geçici görsel yüklemesi yapılır ve dönen URL `https://lens.google.com/uploadbyurl?url=...` parametresiyle `xdg-open` aracılığıyla tarayıcıda açılır.
4. **OCR**: Gri tonlama, kontrast esnetme ve %300 yeniden boyutlandırma filtreleri uygulandıktan sonra sistemde kurulu tüm diller otomatik olarak (`tesseract --list-langs`) Tesseract'a beslenir.

## Sonuçlar ve Ödünleşimler (Consequences & Trade-offs)
- **Hafiflik ve Hız**: Sıfır ek derleme bağımlılığı. Kullanıcı sistemindeki mevcut CLI paketlerinden azami verim alınır.
- **Güvenlik ve İzolasyon**: Tüm geçici dosyalar (`/tmp/omnisnap-*`) işlem bitiminde garantili olarak temizlenir (`rm -f`).
