# AGENTS.md — Omnisnap Geliştirici ve Ajan Kuralları Kılavuzu

> **Önemli:** Bu kod tabanında çalışan tüm yapay zeka ajanları (AI Agents), insan geliştiriciler ve otomasyon araçları bu belgede belirtilen **Andrej Karpathy "LLM Wiki / Living Architecture"** standartlarına uymakla yükümlüdür.

---

## 1. Temel Felsefe: Yaşayan Mimari (Living Architecture)
- Bu depodaki dokümantasyon, statik/ölü bir el kitabı değil; kod değiştikçe eşzamanlı güncellenen **ilişkisel bir mühendislik belleğidir**.
- Kod tabanına eklenen her yeni modül, değiştirilen davranış veya düzeltilen hata doğrudan `docs/omnisnap-wiki/` içerisine yansıtılmalı, fihrist (`index.md`) güncellenmeli ve işlem günlüğüne (`log.md`) append-only kayıt düşülmelidir.

---

## 2. Dizin ve Dosya İsimlendirme Kuralları
1. **Sayısal Sıralama Yasağı (Strict Rule)**:
   - `01-giris.md`, `02-kurulum.md` gibi basılı kitap düzeni taklidi sıralı klasör ve dosya isimleri **kesinlikle yasaktır**.
2. **Kebab-Case Standartı**:
   - Tüm klasörler ve `.md` dosya isimleri küçük harfli ve tireli olmalıdır:
     - `screen-freeze-engine.md` (DOĞRU)
     - `ScreenFreezeEngine.md` (YANLIŞ)
     - `screen_freeze.md` (YANLIŞ)
3. **Fonksiyonel Domain Ayrımı**:
   - Dokümantasyon rastgele dosya yığınları şeklinde değil, aşağıdaki 6 fonksiyonel domain altında tutulur:
     - `docs/omnisnap-wiki/architecture/`: Yüksek seviyeli prensipler, yaşam döngüleri, Wayland LayerShell topolojisi.
     - `docs/omnisnap-wiki/decisions/`: Mimari Karar Kayıtları (`adr-00x-[konu].md`).
     - `docs/omnisnap-wiki/core-engine/`: Ekran yakalama, KWin kenar engelleme, süreç yönetimi.
     - `docs/omnisnap-wiki/ui-components/`: QML bileşenleri, seçim mekaniği, görsel kılavuzlar, araç çubuğu, tema.
     - `docs/omnisnap-wiki/pipelines/`: Kırpma, pano, Swappy, OCR ve Google Lens boru hatları.
     - `docs/omnisnap-wiki/integration/`: CLI, desktop entegrasyonu, kurulum betikleri, test takımı.

---

## 3. Wikilink Sözdizimi ve Graf Hijyeni (Graph Hygiene)
1. **Obsidian Uyumlu Sözdizim**:
   - Standart Markdown bağlantıları (`[metin](dosya.md)`) yerine mutlaka çift köşeli parantezli wikilink formatı kullanılmalıdır:
     - `[[sayfa-adi]]` veya `[[sayfa-adi|Görünen Metin]]`
2. **Düğüm Yumağı Yasağı (Anti-Hairball Rule)**:
   - Her sayfa rasgele her sayfaya bağlanmamalıdır.
   - Bir sayfa yalnızca doğrudan bağımlı olduğu mimari karara ([[adr-xxx]]), veri şemasına veya çekirdek modüle bağlanmalıdır.
   - Sayfa sonlarında mantıksal kümelenmeyi (clustering) pekiştiren "İlişkili Dokümanlar" bloğu bulunmalıdır.

---

## 4. Mimari Karar Kayıtları (ADR) Zorunluluğu
Kod tabanında aşağıdakilerden biri gerçekleştiğinde yeni bir ADR yazılması zorunludur:
- Yeni bir dış bağımlılık veya araç eklendiğinde/değiştirildiğinde.
- Yaşam döngüsü veya IPC mekanizmasında yapısal bir değişiklik yapıldığında.
- KWin/Wayland veya işletim sistemi düzeyinde bir uyumluluk kararı alındığında.

**ADR Formatı:**
- Dosya adı: `docs/omnisnap-wiki/decisions/adr-00x-[kebab-case-konu].md`
- Zorunlu Bölümler:
  1. **Bağlam (Context)**: Çözülmek istenen problem ve kısıtlar.
  2. **Değerlendirilen Alternatifler (Alternatives Considered)**: İncelenen en az 2-3 alternatifin artı/eksileri.
  3. **Karar (Decision)**: Seçilen çözüm ve teknik gerekçesi.
  4. **Sonuçlar ve Ödünleşimler (Consequences & Trade-offs)**: Sisteme getirdiği avantajlar ve göğüslenen maliyetler.

---

## 5. Ajan İş Akışları (Agent Workflows)

### A. Kod Ekleme / Değiştirme Akışı (Ingest Workflow)
Bir ajan kod tabanında değişiklik yaptığında şu sırayı takip eder:
1. İlgili kaynak kodu ve testleri yazar.
2. `tests/run-tests.sh` çalıştırarak tüm testlerin (`tests/test_*.sh`) geçtiğini teyit eder.
3. Yeni bir mimari tercih varsa `decisions/` altında yeni bir ADR oluşturur.
4. İlgili fonksiyonel domaindeki atomik `.md` sayfasını günceller veya yenisini açar (wikilinkleri bağlar).
5. `docs/omnisnap-wiki/index.md` (MOC) dosyasına yeni sayfayı ekler.
6. `docs/omnisnap-wiki/log.md` dosyasına `## [YYYY-MM-DD] [tur] | [Baslik]` formatında bir kayıt ekler.

### B. Kod Sorgulama / Anlama Akışı (Query Workflow)
Bir ajan kod tabanını anlamak istediğinde:
1. İlk önce `docs/omnisnap-wiki/index.md` dosyasını okuyarak ilgili domaini ve sayfaları tespit eder.
2. Tespit edilen atomik sayfalara ve ilgili ADR'lere derinlemesine bakar.
3. Doğrudan kaynak koda geçerek mimari kararların kod üzerindeki izdüşümünü doğrular.

### C. Wiki Bakımı ve Sağlık Taraması (Lint Workflow)
Periyodik olarak:
- Kırık wikilink (`[[olmayan-sayfa]]`) kontrolü yapılır.
- Hiçbir sayfadan bağlantı almayan yetim (orphan) sayfalar tespit edilir ve `index.md` ile ilişkilendirilir.
- Kodda silinen bir parametre veya kütüphane dokümantasyonda kalmışsa ayıklanır.

---

## 6. Proje Doğrulama ve Test Standartları
Herhangi bir PR veya commit öncesinde dinamik test koşucusu çalıştırılmalı ve tüm testlerin geçtiği teyit edilmelidir:
```bash
bash tests/run-tests.sh
```
> **Not:** Yeni bir test yazıldığında dosya adı `tests/test_*.sh` kuralına uyduğu sürece `run-tests.sh` tarafından otomatik olarak keşfedilir ve çalıştırılır; `AGENTS.md` dosyasını her yeni testte manuel olarak güncellemeye gerek yoktur.

İstenirse belirli bir test tekil olarak da çalıştırılabilir:
```bash
bash tests/run-tests.sh test_cli.sh
```

Ayrıca tüm `.qml` dosyalarının Qt 6 `qmllint` sözdizimi denetiminden hatasız geçmesi zorunludur (`test_quickshell_syntax.sh` bu denetimi otomatik olarak yürütür).
