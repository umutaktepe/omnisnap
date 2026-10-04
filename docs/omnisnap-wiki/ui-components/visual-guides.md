# Görsel Kılavuzlar ve Geribildirim (Visual Guides)

Omnisnap, kullanıcının odaklandığı alanı berrak bir şekilde görebilmesi ve piksel hassasiyetinde seçim yapabilmesi için iki temel kılavuz bileşeni sunar:
1. `RectCornersSelectionDetails.qml` (Karartma, Çerçeve, Boyut Göstergesi, Artı Hedef)
2. `CursorGuide.qml` (Dinamik İmleç Takip Hapı)

## 1. Karartma ve Odaklama (`RectCornersSelectionDetails.qml`)

### Akıllı Karartma Çerçevesi (Darken Overlay)
Seçilen alanın dışındaki ekranı karartmak için karmaşık maskeleme (shader/clipping) hesapları yerine yüksek performanslı devasa bir çerçeve (border) tekniği kullanılır:
```qml
Rectangle {
    id: darkenOverlay
    z: 1
    anchors {
        left: parent.left
        top: parent.top
        leftMargin: root.regionX - darkenOverlay.border.width
        topMargin: root.regionY - darkenOverlay.border.width
    }
    width: root.regionWidth + darkenOverlay.border.width * 2
    height: root.regionHeight + darkenOverlay.border.width * 2
    color: "transparent"
    border.color: root.overlayColor // Theme.overlayDarken (%60 siyah)
    border.width: Math.max(root.width, root.height)
}
```
Bu yöntem GPU üzerinde sıfır ek bellek veya karmaşık kompozit dokusu tüketmeden seçili alanı aydınlık bırakır, geri kalan tüm alanı karartır.

### Seçim Çerçevesi ve Dolgusu
- `border.color: Theme.selectionBorder` (Pastel mavi `#89b4fa`)
- `color: Theme.selectionFill` (Saydam mavi `%15` opaklık)

### Piksel Boyut Rozeti (Dimension Badge)
Seçim 10 pikselden büyük olduğunda kutunun sağ alt köşesinde anlık çözünürlüğü gösteren bir rozet belirir:
- Format: `[W] × [H]` (Örnek: `1920 × 1080`)
- Renk ve tipografi: `Theme.primary` ve `Theme.surfaceHigh`

### Artı Hedef Çizgileri (Aim Lines / Crosshairs)
Kullanıcı imlecini hareket ettirirken ekran boyunca uzanan dikey ve yatay 1 piksel genişliğinde %30 opaklıkta kılavuz çizgileri çizilerek imlecin hizalanması kolaylaştırılır.

## 2. Dinamik İmleç Hapı (`CursorGuide.qml`)
Kullanıcı fareyi gezdirirken imlecin 12 piksel sağ ve altında bir bilgi hapı (pill tooltip) eşlik eder.

### Dinamik Mod Metinleri:
- **Copy**: `"Copy region (LMB) or Annotate (RMB)"`
- **Edit**: `"Annotate region with Swappy"`
- **Search**: `"Search with Google Lens"`
- **CharRecognition**: `"Extract text (OCR)"`

### Sürükleme Esnasında Gizlenme:
Kullanıcı seçim yapmaya başladığında (`root.dragging = true`), görüş alanını kapatmamak için imleç hapının opaklığı 150 milisaniyede `0`'a çekilir (`active: !root.dragging`).

## İlişkili Dokümanlar
- Seçim mekaniği: [[selection-mechanics]]
- Tasarım sistemi ve renkler: [[design-system]]
- Katman örtüsü: [[layershell-overlay]]
