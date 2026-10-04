# ADR-002: Çift Yaşam Döngüsü (Oneshot ve Daemon Modu)

- **Durum**: Kabul Edildi
- **Tarih**: 2026-09-28
- **İlgili Bileşenler**: [[execution-lifecycles]], [[cli-interface]], [[process-lifecycle]]

## Bağlam (Context)
Ekran görüntüsü alma araçlarında iki temel kullanıcı profili ve beklentisi bulunur:
1. **Düşük Kaynak Kullanımı İsteyenler**: Sürekli RAM'de arka plan süreci (daemon) tutmak istemeyen, yalnızca kısayola basıldığında aracın açılıp işi bitince tamamen kapanmasını bekleyen kullanıcılar.
2. **Sıfır Gecikme İsteyenler**: Kısayola basıldığı milisaniyede arayüzün açılmasını isteyen ve arka planda çalışan hafif bir servise itirazı olmayan güç kullanıcıları.

Qt/QML tabanlı Quickshell çalışma zamanı (runtime) sıfırdan ayağa kalkarken (cold boot) ~150-250ms başlatma süresine sahip olabilir. Arka planda hazır bekletildiğinde ise tepki süresi ~10ms'ye kadar iner.

## Değerlendirilen Alternatifler (Alternatives Considered)

### 1. Yalnızca Oneshot (Tek Atımlık Süreç)
- **Avantaj**: Sıfır arka plan RAM tüketimi, basit süreç yönetimi.
- **Dezavantaj**: Her tetiklemede QML derleme ve Wayland LayerShell bağlantı gecikmesi hissedilir.

### 2. Yalnızca Daemon (Sürekli Servis)
- **Avantaj**: Anında tepki, IPC üzerinden tek çağrı.
- **Dezavantaj**: Kullanıcıyı arka plan servisi kurmaya ve yönetmeye zorlar. Servis çöktüğünde kısayollar yanıt vermez.

### 3. Çift Yaşam Döngüsü (Dual Lifecycle Hibrit Model)
- **Avantaj**: Varsayılan olarak oneshot modunda sıfır konfigürasyonla çalışır. Kullanıcı dilerse `omnisnap daemon` komutuyla arka plana alabilir. CLI her çağrıda çalışan süreci kontrol eder.
- **Dezavantaj**: CLI katmanında PID kontrolü ve Quickshell IPC müzakeresi karmaşıklığı ekler.

## Karar (Decision)
[[cli-interface]] ve [[execution-lifecycles]] katmanında hibrit çift yaşam döngüsü mimarisi benimsendi.

1. **Varsayılan Oneshot Akışı**:
   - `bin/omnisnap` çalıştırıldığında `pgrep` ile mevcut bir Quickshell süreci aranır.
   - Bulunamazsa `OMNISNAP_INITIAL_ACTION` ortam değişkeni atanarak `quickshell -p .` başlatılır.
   - İşlem tamamlandığında (`dismiss` sinyali veya `snip` bitimi) [[process-lifecycle]] devreye girerek süreci `kill -TERM $Quickshell.processId` ve `Qt.quit()` ile temiz biçimde sonlandırır.

2. **Daemon Akışı**:
   - `omnisnap daemon` arka planda Quickshell'i başlatır.
   - Takip eden CLI çağrıları çalışan süreci tespit ederek doğrudan Quickshell IPC kanalı üzerinden `qs -p . ipc call region [action]` mesajını iletir.
   - İşlem bittiğinde pencereler gizlenir, ana süreç bellekte beklemeye devam eder.

## Sonuçlar ve Ödünleşimler (Consequences & Trade-offs)
- **Esneklik**: Kullanıcı donanım tercihine göre sıfır gecikme (daemon) veya sıfır bellek ayak izi (oneshot) arasında dilediği gibi geçiş yapabilir.
- **IPC Güvenilirliği**: CLI betiği her başlatmada `omnisnap-edges recover` çalıştırarak beklenmeyen kapanmalarda dahi sistem kararlılığını garanti eder.
