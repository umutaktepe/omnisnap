# Metin Tanıma ve Çıkarma (OCR Extraction)

Omnisnap, ekrandaki herhangi bir metin parçasını (kopyalanamayan PDF'ler, görseller, oyun içi metinler veya korumalı web sayfaları) optik karakter tanıma (OCR) ile anında düz yazıya dönüştürür.

Bu eylem `SnipAction.CharRecognition` olarak tanımlanır ve şu yollarla çağrılabilir:
- Alt araç çubuğundaki **OCR Text** sekmesi ([[floating-toolbar]]).
- CLI komutu: `omnisnap ocr` veya `omnisnap -o` ([[cli-interface]]).

## Görüntü Ön İşleme (Image Preprocessing)
Ham ekran pikselleri küçük fontlarda veya düşük kontrastlı arka planlarda doğrudan Tesseract'a verilirse tanıma doğruluğu düşer. Omnisnap, ImageMagick kullanarak görseli OCR için optimize eder:

```bash
magick '$screenshotPath' -crop ... \
    -colorspace gray \
    -type grayscale \
    -contrast-stretch 0 \
    -resize 300% \
    "$TMPF"
```

### Filtrelerin İşlevi:
1. `-colorspace gray -type grayscale`: Renk gürültüsünü ortadan kaldırarak metni siyah/beyaz/gri kontrastına indirger.
2. `-contrast-stretch 0`: Arka plan ile yazı arasındaki tezatlığı maksimum seviyeye çıkarır.
3. `-resize 300%`: Küçük pikselli ekran yazılarını Tesseract'ın en iyi algıladığı 300 DPI eşdeğeri çözünürlüğe büyütür.

## Dinamik Dil Tespiti ve Tesseract Çağrısı
Omnisnap, kullanıcının sisteminde kurulu olan tüm Tesseract dil paketlerini (`tur`, `eng`, `deu` vb.) çalışma anında dinamik olarak keşfeder:

```bash
LANGS=$(tesseract --list-langs 2>/dev/null | awk 'NR>1 && $1!="osd" {print $1}' | tr '\n' '+' | sed 's/\+$//')
if [ -n "$LANGS" ]; then
    TEXT=$(tesseract "$TMPF" stdout -l "$LANGS" 2>/dev/null || true)
else
    TEXT=$(tesseract "$TMPF" stdout 2>/dev/null || true)
fi
```

- Sistemdeki tüm diller `tur+eng` biçiminde birleştirilerek Tesseract'a iletilir.
- Elde edilen metin doğrudan standart çıktıdan (`stdout`) yakalanır.

## Çıktı ve Bildirim
- Metin tespit edilmişse (`[ -n "$TEXT" ]`):
  1. `printf "%s" "$TEXT" | wl-copy` ile Wayland panosuna kopyalanır.
  2. `notify-send "Text Recognized" "$TEXT" -a "Omnisnap"` ile metnin önizlemesi bildirim olarak gösterilir.
- Metin tespit edilemezse:
  - `notify-send "OCR Finished" "No text detected in selected region."` bilgilendirmesi yapılır.

## Test Doğrulaması
`tests/test_action_pipeline.sh` içerisinde ImageMagick ile sentetik "OMNISNAP" yazısı içeren bir test görseli üretilip OCR boru hattına sokulmakta ve Tesseract'ın yazıyı hatasız okuduğu doğrulanmaktadır.

## İlişkili Dokümanlar
- Eylem orkestrasyonu: [[action-orchestration]]
- Görsel kırpma boru hattı: [[image-crop-pipeline]]
- Pano kopyalama: [[clipboard-and-notifications]]
- Mimari karar: [[adr-004-multimodal-post-processing-pipeline]]
