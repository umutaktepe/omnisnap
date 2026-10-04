# Wayland LayerShell Örtüsü (LayerShell Overlay)

Omnisnap arayüzünün temel taşı `modules/screenshot/regionSelector/RegionSelection.qml` bileşenidir. Bu bileşen Quickshell'in `PanelWindow` türünde bir Wayland katman yüzeyidir.

## LayerShell Özellikleri ve Yapılandırması
Geleneksel X11 pencereleri veya Wayland XDG Shell pencereleri masaüstü panellerinin (taskbar, dock) veya diğer pencerelerin altında kalabilir. Omnisnap, Wayland `wlr-layer-shell` protokolünün en üst katmanını kullanır:

```qml
PanelWindow {
    id: root
    required property ShellScreen screen

    // Wayland LayerShell Yapılandırması
    WlrLayershell.namespace: "omnisnap"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }
}
```

### Parametreler ve Rolleri:
- `WlrLayer.Overlay`: Pencereyi tüm masaüstü elemanlarının (paneller, bildirimler, kilit ekranı hariç tam ekran pencereler) üzerine çizer.
- `WlrKeyboardFocus.Exclusive`: Esc veya kısayol tuşlarını doğrudan yakalamak için klavye odağını münhasıran Omnisnap'e kilitler.
- `ExclusionMode.Ignore`: Ekranın kenar panelleri tarafından ayrılmış "rezerv" alanları yok sayar; fiziksel ekranın (0,0) koordinatından (width, height) koordinatına kadar her pikseli kaplar.

## Saydam Başlatma ve Görünürlük Sırası
1. Katman ilk yüklendiğinde `visible: false` ve `color: "transparent"` durumundadır.
2. [[screen-freeze-engine]] arka planda dondurulan görüntüyü hazırlayana kadar arayüz görünmez kalarak kullanıcıya herhangi bir "siyah ekran" veya "boş beyaz flaş" yansıtmaz.
3. Donanım tamponu diske yazılıp `frozenImage.source` atandığı milisaniyede `root.visible = true` yapılarak arayüz kesintisiz olarak sahneye çıkar.

## Klavye Dinleyicileri
- `Shortcut { sequence: "Escape"; onActivated: root.dismiss() }`
- `MouseArea { Keys.onEscapePressed: event => { event.accepted = true; root.dismiss(); } }`
Kullanıcı herhangi bir anda klavyeden `Esc` tuşuna bastığında arayüz derhal kapanır ve sistem önceki durumuna döner ([[process-lifecycle]]).

## İlişkili Dokümanlar
- Seçim mekaniği: [[selection-mechanics]]
- Çoklu monitör yerleşimi: [[multi-display-topology]]
- İşaretçi geçirgenliği: [[adr-005-layershell-pointer-transparency]]
