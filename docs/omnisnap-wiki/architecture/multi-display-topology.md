# Çoklu Ekran Topolojisi (Multi-Display Topology)

Wayland masaüstü mimarisinde çoklu monitör kurulumları; farklı çözünürlükler, farklı yenileme hızları ve bağımsız HiDPI ölçekleme (Fractional Scaling) katsayıları barındırır. Omnisnap, ekranları tek bir yapay sanal tuval olarak değil, her biri bağımsız birer fiziksel çıkış (`ShellScreen`) olarak modeller.

## Ekran Örnekleme Mimarisi (Variants & Loader)
`RegionSelector.qml` içerisinde çoklu ekran yönetimi Quickshell'in `Variants` bileşeniyle sağlanır:

```qml
Variants {
    model: Quickshell.screens
    delegate: Loader {
        id: loader
        required property ShellScreen modelData

        active: root.active
        sourceComponent: RegionSelection {
            screen: loader.modelData
            action: root.action
            onDismiss: root.dismiss()
        }
    }
}
```

### Avantajları:
1. **İzole Bellek Kullanımı**: `active: root.active` koşulu sayesinde seçim modu aktif değilken hiçbir ekran katmanı bellekte çizim (render) yapmaz.
2. **Bağımsız Katman Pencereleri**: Her ekran için ayrı bir [[layershell-overlay]] penceresi (`PanelWindow`) açılır ve o ekranın geometrisine (`screen.x`, `screen.y`, `screen.width`, `screen.height`) kenetlenir.
3. **Ekran Başına Dondurma**: Her ekran kendi donanım tamponunu bağımsız olarak dondurur (`screen-[screen.name].png`).

## HiDPI ve Ölçekleme Katsayısı (Monitor Scale Normalizasyonu)
Farklı ekranlarda (örneğin biri 4K %150 ölçekli, diğeri 1080p %100 ölçekli iki monitör) kullanıcı piksel koordinatları ile arka plandaki ham ekran karesinin piksel koordinatları birebir uyuşmayabilir.

`RegionSelection.qml` içerisindeki hesaplama formülü:
```qml
readonly property real monitorScale: (frozenImage.sourceSize.width > 0 && root.screen.width > 0)
    ? (frozenImage.sourceSize.width / root.screen.width)
    : (root.screen.devicePixelRatio || 1.0)
```

Bu katsayı, kullanıcının fare ile çizdiği seçim koordinatlarını (`regionX`, `regionY`, `regionWidth`, `regionHeight`) ImageMagick kesim motoruna göndermeden önce ölçekler:
- `rx = root.regionX * root.monitorScale`
- `rw = root.regionWidth * root.monitorScale`

Bu sayede kesilen görsel pikselleri hiçbir bulanıklık veya koordinat kayması olmadan 1:1 netlikte elde edilir ([[image-crop-pipeline]]).

## İlişkili Dokümanlar
- Ekran örtüsü katmanı: [[layershell-overlay]]
- Ekran dondurma motoru: [[screen-freeze-engine]]
- Piksel kırpma boru hattı: [[image-crop-pipeline]]
