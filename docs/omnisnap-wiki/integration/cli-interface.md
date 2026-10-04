# Komut Satırı Arayüzü (CLI Interface)

Omnisnap'in birincil kullanıcı ve sistem giriş noktası `bin/omnisnap` bash betiğidir. Bu betik hem kullanıcıların terminalden doğrudan çağırması hem de KDE Plasma masaüstü kısayollarının tetiklemesi için tasarlanmıştır.

## Komut Sözdizimi
```bash
omnisnap [komut]
```

### Desteklenen Komutlar ve Parametreler:

| Komut | Kısa Kod | Açıklama | Davranış |
| :--- | :--- | :--- | :--- |
| `region` | `-r`, `--region` | İnteraktif alan seçimi (varsayılan) | Ekranı dondurur, seçim arayüzünü açar |
| `window` | `-w`, `--window`, `active` | Aktif pencere yakalama | Odaktaki pencereyi anında kaydeder ve panoya kopyalar |
| `full` | `-f`, `--full` | Anında tam ekran yakalama | Arayüz açmadan tüm ekranı doğrudan kaydeder |
| `edit` | `-e`, `--edit` | Düzenleme odaklı alan seçimi | Seçim bitiminde doğrudan Swappy'yi açar |
| `ocr` | `-o`, `--ocr` | Metin çıkarma odaklı alan seçimi | Seçilen alandaki yazıları panoya kopyalar |
| `search` | `-s`, `--search` | Görsel arama odaklı alan seçimi | Seçilen alanı Google Lens'te açar |
| `settings` | `-c`, `--settings`, `config` | Ayarlar penceresi | Çözünürlük, format ve arayüz ayarlarını açar |
| `daemon` | `-d`, `--daemon` | Arka plan servisi başlatma | Quickshell'i bellekte hazır tutar |
| `stop` | `-k`, `--stop` | Arka plan servisini durdurma | Çalışan Quickshell sürecini sonlandırır |
| `status` | - | Servis durumu sorgulama | Daemon çalışıyorsa exit 0, değilse exit 1 döner |
| `help` | `-h`, `--help` | Yardım kılavuzunu görüntüleme | Kullanım talimatlarını ekrana basar |

## Süreç Tespiti ve IPC Yönlendirmesi
CLI betiği, sistemde zaten çalışan bir Omnisnap Quickshell örneği olup olmadığını kontrol eder:

```bash
_is_running() {
    pgrep -f "quickshell.*$PROJECT_DIR" >/dev/null 2>&1 || pgrep -f "quickshell.*$SHELL_FILE" >/dev/null 2>&1
}
```

- **Eğer daemon çalışıyorsa**: `qs -p "$PROJECT_DIR" ipc call region "$action"` komutuyla Quickshell IPC soketine mesaj gönderilir (gecikme < 15ms).
- **Eğer daemon çalışmıyorsa**: Önce `omnisnap-edges recover` ile KWin kenar durumu güvene alınır, ardından `OMNISNAP_INITIAL_ACTION="$action" exec quickshell -p "$PROJECT_DIR"` ile tek seferlik başlatma yapılır ([[execution-lifecycles]]).

## Test Kapsamı
`tests/test_cli.sh` test dosyası:
1. İcrra edilebilir bit kontrolü (`chmod +x`).
2. `--help` çıktısının geçerliliği.
3. Bilinmeyen parametrelerde (`--invalid-arg`) hata kodu `2` ile çıkış yapılması.
4. `status` komutunun çalışan ve çalışmayan durumlarda doğru çıkış kodlarını vermesi.
5. Başlatma öncesi `omnisnap-edges recover` çağrısının yapılması.

## İlişkili Dokümanlar
- Yaşam döngüleri: [[execution-lifecycles]]
- Ekran kenarı kurtarma: [[screen-edge-inhibitor]]
- Masaüstü kısayolları: [[desktop-and-shortcuts]]
- Kurulum: [[installation-and-packaging]]
