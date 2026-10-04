# Test Altyapısı ve Doğrulama (Testing Harness)

Omnisnap, her bir modülün ve boru hattı aşamasının regresyona uğramadan güvenle geliştirilebilmesi için kapsamlı bir bash ve `qmllint` test takımına (`tests/`) sahiptir.

## Test Dosyaları ve Kapsamları

| Test Dosyası | Denetlenen Alanlar |
| :--- | :--- |
| `tests/test_cli.sh` | CLI parametre ayrıştırma, hata kodları, daemon durum tespiti, `recover` entegrasyonu |
| `tests/test_screen_edges.sh` | KWin sıcak köşe engelleme, JSON durum yedekleme, geri yükleme ve kaza kurtarma |
| `tests/test_action_pipeline.sh` | ImageMagick kırpması, shell sözdizimi, asenkron bildirim hızı, Tesseract OCR doğrulaması |
| `tests/test_components.sh` | `Theme.qml`, `Icon.qml`, `IconButton.qml`, `Tooltip.qml` QML sözdizimi ve semantik özellikleri |
| `tests/test_selection_details.sh` | `RectCornersSelectionDetails.qml` ve `CursorGuide.qml` boyut, aim lines ve animasyon testleri |
| `tests/test_toolbar.sh` | `ToolbarTabBar.qml` ve `OptionsToolbar.qml` çift yönlü eylem eşlemesi ve buton yapıları |
| `tests/test_region_selection.sh` | `RegionSelection.qml` ve `RegionSelector.qml` işaretçi geçirgenliği (`enabled: false`), ekran boyutu normalizasyonu |
| `tests/test_quickshell_syntax.sh` | Kod tabanındaki tüm `.qml` dosyalarının `qmllint` ile statik analizi ve sözdizimi denetimi |
| `tests/test_install.sh` | Kurulum betiğinin sembolik bağları ve desktop dosyasını hatasız üretmesi |

## Testleri Çalıştırma

Tüm test paketini dinamik olarak yürütmek için birleşik test koşucusu (`tests/run-tests.sh`) kullanılır:
```bash
bash tests/run-tests.sh
```

Bu araç `tests/test_*.sh` şablonundaki tüm test dosyalarını otomatik olarak keşfeder ve çalıştırır; yeni bir test dosyası eklendiğinde test komutunu güncellemeye gerek kalmaz.

İstenirse tek bir test dosyası filtrelenerek de koşturulabilir:
```bash
bash tests/run-tests.sh test_cli.sh
```

## Statik QML Denetimi (`qmllint`)
`test_quickshell_syntax.sh`, Qt 6'nın resmi `qmllint` aracını kullanarak QML dosyalarında tanımsız özellik, eksik import veya tip uyuşmazlığı olup olmadığını statik olarak analiz eder. Kod tabanında yapılan herhangi bir değişiklik `qmllint` testinden geçmek zorundadır.

## Test Güvenliği ve İzolasyon
Testler kullanıcı sistemindeki gerçek KWin ayarlarını bozmamak için `OMNISNAP_TEST_MODE=1` değişkeniyle sahte geçici dizinler (`mktemp -d`) üzerinde koşar. Test sonlandığında tüm geçici dosyalar temizlenir.

## İlişkili Dokümanlar
- Komut satırı: [[cli-interface]]
- Ekran kenarı koruması: [[screen-edge-inhibitor]]
- Eylem boru hattı: [[action-orchestration]]
- Kurulum: [[installation-and-packaging]]
