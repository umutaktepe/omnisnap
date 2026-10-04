# Çalışma Zamanı Yaşam Döngüleri (Execution Lifecycles)

Omnisnap, kullanıcının bellek ve gecikme tercihlerine göre iki farklı yaşam döngüsü modunu destekleyecek şekilde tasarlanmıştır: **Oneshot (Tek Atımlık Mod)** ve **Daemon (Arka Plan Servis Modu)**.

Bu ikili yapı hakkındaki mimari karar için bkz: [[adr-002-dual-lifecycle-oneshot-and-daemon]].

## 1. Oneshot Modu (Varsayılan)
Kullanıcı herhangi bir arka plan servisi çalıştırmak istemediğinde devreye giren moddur.

### Akış Aşamaları:
1. Kullanıcı `omnisnap region` veya `omnisnap full` komutunu çalıştırır.
2. `bin/omnisnap` betiği `pgrep` ile çalışan bir Quickshell örneği arar. Bulunamazsa:
   - [[screen-edge-inhibitor]] çağrısı yaparak olası askıda kalmış durumları kurtarır (`omnisnap-edges recover`).
   - `OMNISNAP_INITIAL_ACTION` ortam değişkenine istenen eylemi (`screenshot`, `edit`, `ocr`, `search`, `fullscreen`) yazar.
   - `quickshell -p .` sürecini başlatır.
3. `shell.qml` dosyasındaki `Component.onCompleted` bloğu bu ortam değişkenini okur ve ilgili eylemi anında tetikler.
4. Kullanıcı ekran seçimini tamamladığında veya Esc tuşuyla iptal ettiğinde:
   - [[screen-edge-inhibitor]] orijinal KWin ayarlarını geri yükler.
   - Geçici ekran dosyaları temizlenir.
   - `RegionSelector.qml` içerisindeki `dismiss()` fonksiyonu `Quickshell.execDetached(["kill", "-TERM", `${Quickshell.processId}`])` ve `Qt.quit()` çağrısı yaparak süreci bellekten tamamen kaldırır ([[process-lifecycle]]).

## 2. Daemon Modu (Sıfır Gecikme)
Sistem kaynaklarının hazır tutularak kısayola basıldığı anda 10 milisaniyenin altında tepki verilmesini sağlayan moddur.

### Akış Aşamaları:
1. Kullanıcı oturum açılışında veya terminalden `omnisnap daemon` komutunu yürütür.
2. Quickshell arka planda başlatılır ve `shell.qml` içerisindeki `IpcHandler` soketi aktif hale gelir.
3. Kullanıcı kısayol tuşuna bastığında `bin/omnisnap`:
   - Çalışan bir Quickshell süreci tespit eder.
   - `qs -p [proje-dizini] ipc call region [eylem]` IPC komutunu yürütür.
4. `shell.qml` içerisindeki `IpcHandler { target: "region" }` gelen IPC çağrısını karşılar ve ilgili ekran seçim katmanını anında öne çıkarır.
5. İşlem bittiğinde `RegionSelector.qml` pencereleri gizler (`active = false`), ancak ana Quickshell süreci kapanmaz; RAM'de bir sonraki çağrıyı bekler.

## Yaşam Döngüsü Karşılaştırması

| Özellik | Oneshot Modu | Daemon Modu |
| :--- | :--- | :--- |
| **Başlatma Gecikmesi** | ~150 - 250 ms (QML boot) | < 15 ms (Sıfır gecikme) |
| **Bellek Tüketimi (Bekleme)** | 0 MB (Tamamen kapalı) | ~30 - 45 MB RAM |
| **Süreç Yönetimi** | Otomatik sonlanma | `omnisnap stop` ile kapatılır |
| **İletişim Kanalı** | Ortam Değişkeni (`OMNISNAP_INITIAL_ACTION`) | Quickshell IPC Soketi |

## İlişkili Dokümanlar
- Giriş noktası: [[cli-interface]]
- Süreç sonlanma adımları: [[process-lifecycle]]
- Mimari karar: [[adr-002-dual-lifecycle-oneshot-and-daemon]]
