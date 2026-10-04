# Kayan Alt Araç Çubuğu (Floating Toolbar)

Omnisnap, kullanıcının ekran görüntüsü modunu çalışma anında değiştirebilmesi ve ek eylemler yürütebilmesi için ekranın alt ortasında yüzen modern bir hap araç çubuğu (`OptionsToolbar.qml` ve `ToolbarTabBar.qml`) sunar.

## Araç Çubuğu Mimarisi ve Yerleşimi
Araç çubuğu `RegionSelection.qml` hiyerarşisinde `MouseArea` içerisine değil, onun bir üst katmanına (`z: 100`) kardeş olarak yerleştirilmiştir:

```qml
OptionsToolbar {
    id: optionsToolbar
    z: 100
    anchors {
        horizontalCenter: parent.horizontalCenter
        bottom: parent.bottom
        bottomMargin: 16
    }
    action: root.action
    onActionChanged: {
        if (optionsToolbar.action !== undefined && root.action !== optionsToolbar.action) {
            root.action = optionsToolbar.action;
        }
    }
    onDismiss: root.dismiss()
    onFullScreenRequested: {
        root.snip(true);
    }
}
```

Bu yerleşim, farenin araç çubuğu üzerindeki düğmelere tıklamasını ve sekmeleri değiştirmesini sağlarken, çubuk dışındaki alanlarda seçim mekanizmasının kesintisiz çalışmasını temin eder ([[adr-005-layershell-pointer-transparency]]).

## Bileşen Yapısı ve Düğmeler

```
┌────────────────────────────────────────────────────────────────────────┐
│  [✂ Screenshot]  [✏ Annotate]  [🔍 Google Lens]  [🔤 OCR Text]  │  [⛶]  [✕] │
└────────────────────────────────────────────────────────────────────────┘
```

1. **`ToolbarTabBar.qml` (Mod Sekmeleri)**:
   - **Screenshot** (`content_cut`): Seçilen alanı panoya kopyalar ve dosyaya kaydeder.
   - **Annotate** (`edit`): Seçilen alanı Swappy çizim aracına devreder.
   - **Google Lens** (`search`): Seçilen alanı Uguu'ya yükleyip Google Lens'te aratır.
   - **OCR Text** (`ocr`): Seçilen alandaki yazıları Tesseract ile okuyup panoya kopyalar.
   - Sekmeler arasında geçiş yapıldığında `root.action` reaktif olarak güncellenir ve [[visual-guides]] içerisindeki imleç hapı da anında yeni moda uyarlanır.

2. **Dikey Ayırıcı (Divider)**:
   - Sekmeler ile bağımsız butonlar arasında 1 piksel genişliğinde `Theme.outline` çizgisidir.

3. **Tam Ekran Düğmesi (`fsBtn`)**:
   - `icon: "fullscreen"`
   - `onClicked: root.fullScreenRequested()`
   - Tıklandığında sürükleme koordinatları yerine ekranın tüm çözünürlüğünü (`0, 0, screen.width, screen.height`) kırpma boru hattına gönderir.

4. **Kapatma / İptal Düğmesi (`closeBtn`)**:
   - `icon: "close"`
   - `onClicked: root.dismiss()`
   - Klavyedeki Esc tuşuyla aynı görevi görerek arayüzü kapatır ve geçici dosyaları temizler.

## Tasarım Özellikleri
- Yükseklik: 48 piksel.
- Kenar yuvarlama (Border Radius): `height / 2` (Tam hap / pill biçimi).
- Arka plan: `Theme.surface` (`#28283d`).
- Çerçeve: 1 piksel `Theme.outline` (`#45475a`).

## İlişkili Dokümanlar
- Tasarım sistemi: [[design-system]]
- Seçim mekaniği: [[selection-mechanics]]
- Eylem boru hattı: [[action-orchestration]]
- İşaretçi geçirgenliği kararı: [[adr-005-layershell-pointer-transparency]]
