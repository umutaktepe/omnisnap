# ADR-005: LayerShell İşaretçi Olayı Geçirgenliği (Pointer Event Transparency)

- **Durum**: Kabul Edildi
- **Tarih**: 2026-09-28
- **İlgili Bileşenler**: [[layershell-overlay]], [[selection-mechanics]], [[visual-guides]], [[floating-toolbar]]

## Bağlam (Context)
Ekran görüntüsü alma arayüzünde tam ekran bir `MouseArea` kullanıcının sürükleme (drag) ve bırakma (release) hareketlerini takip eder. Ancak bu `MouseArea` üzerinde aynı zamanda görsel kılavuzlar (seçim çerçevesi, karartma katmanı, artı hedef çizgileri, piksel boyut etiketi ve imleç takip hapı) render edilir.

İlk uygulamada bu görsel bileşenlerin QtQuick hiyerarşisinde `MouseArea` içerisinde yer alması ve fare tıklama olaylarını istemeden yutması (event hijacking) nedeniyle fare bırakıldığında `onReleased` sinyalinin tetiklenmediği ve ekran görüntüsünün kaydedilmediği bir hata yaşanmıştır.

## Değerlendirilen Alternatifler (Alternatives Considered)

### 1. Her Alt Bileşene Özel MouseArea ve Olay İletimi (Event Propagation)
- **Avantaj**: Her bileşenin kendi içinde fare durumunu bilmesi.
- **Dezavantaj**: Kod tabanını aşırı karmaşıklaştırır, gecikme ekler ve yarış durumlarına (race condition) sebep olur.

### 2. Görsel Katmanları Tümüyle Devre Dışı Bırakmak (`enabled: false`) ve Araç Çubuğunu Ayrıştırmak
- **Avantaj**: Kesin çözüm. Görsel geribildirim sağlayan tüm öğeleri (`RectCornersSelectionDetails`, `CursorGuide`) `enabled: false` olarak işaretleyerek tıklama olaylarına karşı tamamen "saydam" kılmak; tıklanabilir tek öğe olan alt araç çubuğunu (`OptionsToolbar`) ise `MouseArea` dışına ve yüksek bir Z indeksine (`z: 100`) kardeş (sibling) olarak yerleştirmek.
- **Dezavantaj**: UI hiyerarşisinde dikkatli bir yerleşim disiplini gerektirir.

## Karar (Decision)
[[selection-mechanics]] ve [[layershell-overlay]] katmanında tam işaretçi geçirgenliği (pointer event transparency) prensibi kabul edildi:

1. **Görsel Katman Saydamlığı**:
   - `RectCornersSelectionDetails` -> `enabled: false`
   - `CursorGuide` -> `enabled: false`
   Bu sayede fare tıklamaları ve sürüklemeleri doğrudan altındaki ana `MouseArea` tarafından kesintisiz olarak algılanır.

2. **Araç Çubuğu İzolasyonu**:
   - `OptionsToolbar`, `MouseArea`'nın çocuğu değil, kardeşidir.
   - `z: 100` derinliği ile araç çubuğuna tıklanıldığında sekme değiştirme veya tam ekran düğmesi sorunsuz çalışır, ancak etrafındaki ekranda sürükleme yapıldığında ana seçim alanı kontrolü ele alır.

## Sonuçlar ve Ödünleşimler (Consequences & Trade-offs)
- **Kusursuz Fare Takibi**: Fare bırakıldığı anda `onReleased` güvenle tetiklenir, `snip()` fonksiyonu hiçbir zaman ıskalanmaz.
- **Mimari Temizlik**: Tıklanabilir arayüz elemanları ile saf görsel katmanlar net bir şekilde ayrıştırılmıştır.
