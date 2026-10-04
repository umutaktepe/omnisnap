# Çizim ve Not Ekleme Entegrasyonu (Swappy Annotation)

Omnisnap, yakalanan ekran görüntülerine hızlıca ok, dikdörtgen, bulanıklaştırma (blur) veya metin eklemek için Wayland ekosisteminin standart aracı olan **Swappy** ile doğrudan el sıkışır (hand-off).

Bu eylem `SnipAction.Edit` olarak tanımlanır ve şu yollarla tetiklenebilir:
1. Alt araç çubuğundaki **Annotate** sekmesini seçerek ([[floating-toolbar]]).
2. Varsayılan kopyalama modundayken fareyi sağ tık (RMB) ile sürükleyerek ([[selection-mechanics]]).
3. Terminalden `omnisnap edit` veya `omnisnap -e` kısayoluyla ([[cli-interface]]).

## Boru Hattı Akışı
```bash
set -euo pipefail;
SAVE_DIR='~/Pictures/Screenshots';
SAVE_DIR="${SAVE_DIR/#\~/$HOME}";
mkdir -p "$SAVE_DIR" &&
saveFile="$SAVE_DIR/screenshot-$(date +%Y-%m-%d_%H.%M.%S).png" &&
TMPF=$(mktemp /tmp/omnisnap-edit-XXXXXX.png);
magick '$screenshotPath' -crop ... "$TMPF" &&
swappy -f "$TMPF" -o "$saveFile" || true;
if [ -s "$saveFile" ]; then
    wl-copy -t image/png < "$saveFile";
    notify-send "Screenshot Edited" "Saved to $saveFile" -i "$saveFile" -a "Omnisnap" 2>/dev/null || true;
fi;
rm -f "$TMPF";
rm -f '$screenshotPath';
```

## Güvenlik ve İptal Yönetimi
- Kullanıcı Swappy penceresini açtıktan sonra kaydetmeden pencereyi kapatırsa (`saveFile` oluşmaz veya boş kalırsa):
  - `[ -s "$saveFile" ]` kontrolü sayesinde panoya boş veri kopyalanmaz ve bildirim gönderilmez.
- Geçici dosya `TMPF` işlem başarılı olsa da olmasa da en sonda güvenli şekilde silinir.
- Kaydedilen görsel hem diske saklanır hem de anında `wl-copy` ile panoya yüklenir.

## İlişkili Dokümanlar
- Eylem orkestrasyonu: [[action-orchestration]]
- Görsel kırpma boru hattı: [[image-crop-pipeline]]
- Pano kopyalama: [[clipboard-and-notifications]]
- Mimari karar: [[adr-004-multimodal-post-processing-pipeline]]
