# Seçim Mekaniği ve Geometri (Selection Mechanics)

Omnisnap, kullanıcının fare imleci ile serbestçe sürükleyerek dikdörtgen bir alan seçmesini sağlayan zengin bir etkileşim motoruna sahiptir.

İşaretçi geçirgenliği ve olayların ayrıştırılması ile ilgili mimari karar için bkz: [[adr-005-layershell-pointer-transparency]].

## Koordinat ve Geometri Hesaplaması
Kullanıcı fareyi herhangi bir yöne (soldan sağa, sağdan sola, yukarıdan aşağıya veya çapraz) sürükleyebilir. `RegionSelection.qml` içerisindeki reaktif özellikler (reactive properties) negatif genişlik ve yükseklik oluşmasını engeller:

```qml
property real dragStartX: 0
property real dragStartY: 0
property real draggingX: 0
property real draggingY: 0
property bool dragging: false

property real regionWidth: Math.abs(draggingX - dragStartX)
property real regionHeight: Math.abs(draggingY - dragStartY)
property real regionX: Math.min(dragStartX, draggingX)
property real regionY: Math.min(dragStartY, draggingY)
```

## Etkileşim Kuralları

### 1. Sol Tık vs Sağ Tık Eylem Ayrımı
- **Sol Tık (LMB)**: Geçerli araç çubuğu eylemini (varsayılan: panoya kopyalama / dosya kaydetme) yürütür.
- **Sağ Tık (RMB) Kısayolu**: Kullanıcı araç çubuğunu değiştirmeden yalnızca sağ tık ile bir alan seçtiğinde, `root.action === Copy` ise eylem otomatik olarak `Edit` (Swappy düzenleyicisi) moduna dönüştürülür:
```qml
if (root.mouseButton === Qt.RightButton && finalAction === ScreenshotAction.SnipAction.Copy) {
    finalAction = ScreenshotAction.SnipAction.Edit;
}
```

### 2. Mikro Tıklama Toleransı (Tam Ekran Koruması)
Kullanıcı ekranda sürükleme yapmadan sadece ekrana tıklayıp bıraktığında (`rw < 4 || rh < 4`):
```qml
if (rw < 4 || rh < 4) {
    rx = 0;
    ry = 0;
    rw = root.screen.width;
    rh = root.screen.height;
}
```
Bu sayede yanlışlıkla yapılan kazara boş tıklamalar başarısız bir hata fırlatmak yerine doğrudan o monitörün tam ekran görüntüsünü yakalar.

### 3. HiDPI Normalizasyonu
Seçilen piksel sınırları donanım karesine göre dönüştürülür:
```qml
const cmd = ScreenshotAction.getCommand(
    rx * root.monitorScale,
    ry * root.monitorScale,
    rw * root.monitorScale,
    rh * root.monitorScale,
    proc.screenshotPath,
    finalAction
);
```

## Olay Yutulmasının Önlenmesi (`enabled: false`)
Görsel göstergelerin (`RectCornersSelectionDetails` ve `CursorGuide`) fare hareketlerini engellememesi için `enabled: false` atanmıştır. Alt araç çubuğu (`OptionsToolbar`) ise `z: 100` ile bağımsız bir katmandadır ([[adr-005-layershell-pointer-transparency]]).

## İlişkili Dokümanlar
- Görsel kılavuzlar: [[visual-guides]]
- Katman örtüsü: [[layershell-overlay]]
- Araç çubuğu etkileşimi: [[floating-toolbar]]
- Eylem boru hattı: [[action-orchestration]]
