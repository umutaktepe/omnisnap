# Görsel Kırpma Boru Hattı (Image Crop Pipeline)

Görsel kırpma, Omnisnap'in tüm son işlem eylemlerinin ortak ilk adımıdır. Dondurulmuş tam ekran dosyasından kullanıcının seçtiği koordinatlara karşılık gelen pikseller ImageMagick (`magick`) aracıyla kesilir.

## ImageMagick Kırpma Komutu
`ScreenshotAction.qml` içerisinde kırpma taban komutu şu şekilde tanımlanır:

```bash
cropBase="magick '${escapeShellStr(screenshotPath)}' -crop ${rw}x${rh}+${rx}+${ry} +repage"
```

### Parametre Detayları:
- `-crop ${rw}x${rh}+${rx}+${ry}`: Belirtilen genişlik (`rw`), yükseklik (`rh`), x başlangıcı (`rx`) ve y başlangıcını (`ry`) temsil eder.
- `+repage`: Kırpılan görselin orijinal sanal tuval ofset (canvas page offset) bilgilerini sıfırlar. Bu parametre olmadan kırpılan PNG dosyaları bazı görüntüleyicilerde veya Swappy'de orijinal koordinatlarında boşluklu olarak açılabilir.

## HiDPI ve Yuvarlama Disiplini
Seçim koordinatları QML tarafında kayan noktalı (floating-point) sayılar olabilir (örneğin `124.6px`). ImageMagick komutuna gönderilmeden önce `Math.round()` ile tam sayılara dönüştürülür:
```javascript
const rx = Math.round(x);
const ry = Math.round(y);
const rw = Math.round(width);
const rh = Math.round(height);
```

Ayrıca ekranın HiDPI ölçekleme çarpanı ([[multi-display-topology]]) bu koordinatlarla çarpılmış olarak fonksiyona iletilir. Bu sayede 4K ekranda alınan ekran görüntüsü donanım çözünürlüğünde kesilir.

## Test Doğrulaması
Boru hattının stabilitesi `tests/test_action_pipeline.sh` dosyasında sentetik bir 200x200 mavi tuval oluşturulup 50x50 boyutunda kırpılarak ve `identify` ile piksel boyutları teyit edilerek test edilmektedir.

## İlişkili Dokümanlar
- Eylem orkestrasyonu: [[action-orchestration]]
- Çoklu ekran topolojisi: [[multi-display-topology]]
- Mimari karar: [[adr-004-multimodal-post-processing-pipeline]]
