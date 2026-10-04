# ADR-003: KWin Ekran Kenarı ve Sıcak Köşe Engelleme (Screen Edge Inhibition)

- **Durum**: Kabul Edildi
- **Tarih**: 2026-09-28
- **İlgili Bileşenler**: [[screen-edge-inhibitor]], [[layershell-overlay]], [[cli-interface]]

## Bağlam (Context)
KDE Plasma 6 KWin pencere yöneticisi, ekran kenarlarına ve köşelerine fare imleci değdiğinde tetiklenen "Sıcak Köşeler" (Hot Corners / Electric Borders) özelliğine sahiptir (özellikle sol üst köşedeki Genel Bakış / Overview efekti).

Kullanıcı ekranın en sol veya en üst kenarından başlayarak bir alan seçmeye çalıştığında imleç köşeye çarpar çarpmaz KWin genel bakış moduna geçmekte ve seçim kutusunu bölerek ekran yakalama akışını bozmaktaydı.

## Değerlendirilen Alternatifler (Alternatives Considered)

### 1. Wayland Pointer Constraint / Cursor Grab
- **Avantaj**: İmlecin ekran sınırlarını aşmasını yazılımsal olarak kısıtlamak.
- **Dezavantaj**: Wayland LayerShell protokolünde global kilitlenme/grab mekanizması güvenlik ve mimari gereği sınırlandırılmıştır; KWin elektrikli kenarlarını bypass etmeye yetmez.

### 2. Kullanıcıyı Ayarları Kapatmaya Zorlamak
- **Avantaj**: Kod tabanına sıfır karmaşıklık.
- **Dezavantaj**: Kötü kullanıcı deneyimi; kullanıcının masaüstü tercihlerini kalıcı olarak feda etmesini talep etmek kabul edilemez.

### 3. Dinamik KWin Yapılandırma Maskelemesi ve Geri Yükleme (State Snapshot)
- **Avantaj**: Omnisnap açıldığında mevcut kenar konfigürasyonunu geçici bir JSON dosyasına yedekler, kenarları geçici olarak `None` / `9` (ElectricNone) yapar ve KWin'i yeniden yapılandırır (`reconfigure`). Seçim tamamlandığında veya iptal edildiğinde ayarları orijinal haline eksiksiz geri yükler.
- **Dezavantaj**: KWin DBus çağrıları ve `kwriteconfig6` yönetimi gerektirir; çökme durumlarında ayarların askıda kalma riski bulunur.

## Karar (Decision)
[[screen-edge-inhibitor]] sorumluluğunu üstlenen bağımsız `bin/omnisnap-edges` CLI modülü geliştirildi.

- **Inhibit**: Seçim başladığında `Effect-overview` ve `ElectricBorders` anahtarlarını `$XDG_RUNTIME_DIR/omnisnap/stolen-screen-edges.json` dosyasına kaydeder ve KWin'de geçici olarak etkisizleştirir.
- **Restore**: Seçim sonlandığında JSON dosyasını okuyarak orijinal anahtarları yerine yazar ve dosyayı siler.
- **Crash Recovery**: Olası bir SIGKILL veya sistem çökmesi durumunda ayarların kaybolmaması için `bin/omnisnap` her başlatılışında `omnisnap-edges recover` çağrısı yaparak askıda kalmış durum dosyalarını temizler ve KWin'i geri yükler.

## Sonuçlar ve Ödünleşimler (Consequences & Trade-offs)
- **Kusursuz Seçim Deneyimi**: Kullanıcı ekranın en köşesine kadar fareyi sürüklese dahi hiçbir masaüstü efekti tetiklenmez.
- **Hata Toleransı**: JSON durum yedekleme ve otomatik kurtarma mekanizması sayesinde kullanıcının kişisel masaüstü ayarları asla kalıcı olarak bozulmaz.
