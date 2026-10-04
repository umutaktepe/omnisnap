# Tasarım Sistemi ve Temel Bileşenler (Design System)

Omnisnap, KDE Plasma 6 Breeze Dark ve modern Material You / Catppuccin Mocha renk paletlerinden ilham alan, kendi içinde kapalı (self-contained) ve harici C++ temalama eklentilerine bağımlılığı olmayan bir tasarım sistemi kullanır.

## Renk Paleti: `theme/Theme.qml`
`Theme.qml`, QML `pragma Singleton` olarak tanımlanmış merkezi renk deposudur:

| Token | Değer (Hex/RGBA) | Kullanım Alanı |
| :--- | :--- | :--- |
| `background` | `#1e1e2e` | Ana arayüz arka planı |
| `surface` | `#28283d` | Kart ve araç çubuğu gövdesi |
| `surfaceHigh` | `#313244` | Vurgulu haplar, buton hover durumları ve etiketler |
| `primary` | `#89b4fa` | Pastel mavi; aktif sekme, imleç simgeleri, seçim kenarları |
| `onPrimary` | `#11111b` | Birincil renk üzeri kontrast metin |
| `secondary` | `#b4befe` | İkincil pastel mor vurgular |
| `outline` | `#45475a` | Kart ve buton sınır çizgileri |
| `text` | `#cdd6f4` | Birincil okuma metinleri |
| `textMuted` | `#a6adc8` | Pasif metinler ve açıklamalar |
| `overlayDarken` | `rgba(0, 0, 0, 0.6)` | Seçim dışı alanı karartma katmanı |
| `selectionBorder` | `#89b4fa` | Seçilen alanın çevre çizgisi |
| `selectionFill` | `rgba(137, 180, 250, 0.15)` | Seçilen alanın iç dolgusu |

## Atomik Kullanıcı Arayüzü Bileşenleri (`components/`)

### 1. `Icon.qml`
Sistem freedesktop simge temasını (`Quickshell.iconPath`) kullanarak sembolik isimleri eşleştiren adaptördür:
- `screenshot` / `content_cut` -> `edit-cut` / `image-crop`
- `edit` / `brush` -> `document-edit` / `draw-freehand`
- `search` / `image_search` -> `search` / `system-search`
- `ocr` / `text_fields` -> `edit-find-replace` / `character-set`
- `fullscreen` -> `view-fullscreen` / `window-maximize`
- `close` -> `window-close` / `dialog-close`

### 2. `IconButton.qml`
Fare ile üzerine gelindiğinde (hover) yumuşak geçişli (`ColorAnimation`, 120ms) arka plan ve kenarlık rengi değişen, tıklanabilir yuvarlak buton bileşenidir.

### 3. `StyledText.qml`
Yüksek çözünürlüklü ekranlarda pürüzsüz yazı kalitesi sağlamak için `renderType: Text.NativeRendering` özelliğini kullanan ve sistem fontlarını (`Noto Sans`, `Inter`, `Roboto`, `sans-serif`) önceliklendiren metin sarmalayıcısıdır.

### 4. `Tooltip.qml`
Herhangi bir hedef bileşene (`target`) bağlanabilen, hedef üzerine gelindiğinde 150 milisaniyelik yumuşak opaklık animasyonuyla beliren ve buton ipuçlarını gösteren bilgilendirme baloncuğudur.

## İlişkili Dokümanlar
- Kayan araç çubuğu: [[floating-toolbar]]
- Görsel kılavuzlar: [[visual-guides]]
- Katman örtüsü: [[layershell-overlay]]
