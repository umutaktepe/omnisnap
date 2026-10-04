# Eylem Orkestrasyonu (Action Orchestration)

Omnisnap'in kırpma ve son işleme operasyonları `modules/screenshot/ScreenshotAction.qml` singleton bileşeni tarafından yönetilir. Bu bileşen, kullanıcı tarafından seçilen dikdörtgen koordinatları ve aktif eylem modunu alarak tek bir optimize edilmiş, hataya dayanıklı bash komutu üretir.

Mimari kararın detayları için bkz: [[adr-004-multimodal-post-processing-pipeline]].

## Eylem Numaralandırması (SnipAction Enum)
```qml
enum SnipAction {
    Copy,
    Edit,
    Search,
    CharRecognition
}
```

## Komut Üretim Arabirimi: `getCommand`
```qml
function getCommand(x, y, width, height, screenshotPath, action, saveDir = "") {
    const script = root.getScript(x, y, width, height, screenshotPath, action, saveDir);
    return script ? ["bash", "-c", script] : [];
}
```

Bu arabirim doğrudan `Quickshell.execDetached(cmd)` çağrısına beslenir. Süreç ana arayüzden bağımsız (detached) çalıştığı için Omnisnap arayüzü kapansa bile arka plandaki yükleme veya OCR işlemleri kesintiye uğramaz.

## Shell Kaçış Güvenliği (Shell Escaping)
Dosya yollarında boşluk veya özel karakterler bulunması ihtimaline karşı `escapeShellStr` fonksiyonu kullanılır:
```javascript
function escapeShellStr(str) {
    if (!str) return "''";
    return str.replace(/'/g, "'\\''");
}
```

## Genel Akış ve Hata Yönetimi
Tüm üretilen kabuk betikleri `set -euo pipefail` ile başlatılır. Bu sayede boru hattındaki herhangi bir adım (örneğin ImageMagick kırpması) başarısız olursa betik anında durur ve bozuk veri panoya aktarılmaz. Betiklerin sonunda mutlaka geçici ekran karesini silen `cleanup` (`rm -f '${escapeShellStr(screenshotPath)}'`) komutu yer alır ([[process-lifecycle]]).

## İlişkili Eylemler ve Boru Hatları
- Görsel kırpma mantığı: [[image-crop-pipeline]]
- Pano kopyalama ve masaüstü bildirimleri: [[clipboard-and-notifications]]
- Çizim ve düzenleme entegrasyonu: [[annotation-swappy]]
- Optik karakter tanıma: [[ocr-extraction]]
- Google Lens görsel arama: [[lens-visual-search]]
- Mimari karar: [[adr-004-multimodal-post-processing-pipeline]]
