# Ekran Dondurma Motoru (Screen Freeze Engine)

Ekran Dondurma Motoru, kullanıcının ekran görüntüsü alma kısayoluna bastığı andaki masaüstü durumunu anında sabitleyen ve üzerinde görsel seçim yapılabilmesini sağlayan çekirdek mekanizmadır.

Mimari kararın detayları için bkz: [[adr-001-screen-freeze-via-spectacle]].

## Uygulama Bileşeni: `TempScreenshotProcess.qml`
Her ekran için bir adet `TempScreenshotProcess` oluşturulur. Bu bileşen Quickshell'in `Quickshell.Io.Process` API'sini kullanarak KDE'nin yerleşik ekran yakalama aracı olan Spectacle'ı tetikler.

### Komut Yapısı:
```qml
Process {
    id: screenshotProc
    required property ShellScreen screen

    property string screenshotDir: `${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/omnisnap`
    property string screenshotPath: `${screenshotDir}/screen-${screen.name}.png`

    running: true
    command: [
        "bash", "-c",
        `mkdir -p '${_safeDir}' && spectacle -b -n -m -o '${_safePath}'`
    ]
}
```

### Parametrelerin Anlamı:
- `-b` (`--background`): Kullanıcıya hiçbir Spectacle penceresi veya GUI diyaloğu göstermeden sessizce çalışır.
- `-n` (`--nonotify`): Sistem bildirimini engeller (kullanıcıya çift bildirim gitmemesi için).
- `-m` (`--current`): Komutun hedeflediği geçerli monitör karesini yakalar.
- `-o` (`--output`): Yakalanan ham görüntüyü hedef dosya yoluna yazar.

## Dondurulan Görüntünün Tuvale Yüklenmesi
Süreç tamamlandığında (`onExited` sinyali):
1. `RegionSelection.qml` içerisindeki `Image { id: frozenImage }` bileşeni dosya yolunu okur (`"file://" + proc.screenshotPath`).
2. Pencere görünür hale gelir (`root.visible = true`).
3. Fare odağı doğrudan `mouseArea` üzerine aktarılır (`mouseArea.forceActiveFocus()`).
4. Kullanıcı, arka planda masaüstündeki videolar veya pencereler hareket etse bile kendi gördüğü dondurulmuş anlık kare üzerinde seçim yapmaya başlar.

## Geçici Dosya Yönetimi ve Temizlik
- Seçim başarıyla tamamlandığında [[action-orchestration]] betiği hedef kırpma işlemini yaptıktan sonra arka planda geçici dosyayı anında siler (`rm -f`).
- Seçim Esc tuşuyla iptal edildiğinde `RegionSelection.qml` içerisindeki `onDismiss` sinyali tetiklenerek dosya güvenle temizlenir:
```qml
onDismiss: {
    if (!root.snipExecuted && proc.screenshotPath) {
        Quickshell.execDetached(["rm", "-f", proc.screenshotPath]);
    }
}
```

## İlişkili Dokümanlar
- Katman örtüsü: [[layershell-overlay]]
- Çoklu monitör geometrisi: [[multi-display-topology]]
- Mimari karar: [[adr-001-screen-freeze-via-spectacle]]
