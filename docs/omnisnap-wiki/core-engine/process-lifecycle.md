# Süreç Yaşam Döngüsü ve Temizlik (Process Lifecycle)

Omnisnap'in sistem düzeyindeki süreç yönetimi; arka planda zombi süreç bırakmama, geçici dosyaları anında imha etme ve Wayland masaüstü kaynaklarını serbest bırakma prensiplerine dayanır.

## Süreç Başlatma ve Parametre İletimi
`bin/omnisnap` CLI betiği, Quickshell'i başlatırken çalışma amacını ortam değişkeni aracılığıyla aktarır:

```bash
_launch_oneshot() {
    local action="$1"
    "$PROJECT_DIR/bin/omnisnap-edges" recover 2>/dev/null || true
    OMNISNAP_INITIAL_ACTION="$action" exec quickshell -p "$PROJECT_DIR"
}
```

Bu modelde `exec` kullanılarak bash ara kabuğu doğrudan Quickshell süreciyle yer değiştirir; gereksiz alt kabuk süreçleri engellenir.

## Kapanış ve Temiz Çıkış (Graceful Shutdown)
Oneshot modunda ekran görüntüsü alındıktan veya Esc ile iptal edildikten sonra sistemin askıda kalmaması kritik bir gereksinimdir.

`RegionSelector.qml` içerisindeki `dismiss()` fonksiyonu:
```qml
function dismiss() {
    Quickshell.execDetached([edgesBin(), "restore"]);
    root.active = false;
    // If not running in daemon mode, quit quickshell
    if (Quickshell.env("OMNISNAP_DAEMON") !== "1" && Quickshell.env("OMNISNAP_INITIAL_ACTION") !== "") {
        Quickshell.execDetached(["kill", "-TERM", `${Quickshell.processId}`]);
        Qt.quit();
    }
}
```

### Neden Çift Sonlandırma (`kill -TERM` + `Qt.quit()`)?
Wayland LayerShell pencereleri bazen Wayland soket olay döngüsünü beklerken `Qt.quit()` çağrısını geciktirebilir. `kill -TERM ${Quickshell.processId}` sinyaliyle sürecin anında ve temiz biçimde (zombi bırakmadan) işletim sistemi tarafından sonlandırılması garanti altına alınır.

## Dosya Sistemi Temizlik Garantileri
Omnisnap'in diskte oluşturduğu iki geçici dosya kategorisi vardır:
1. **Dondurulmuş Tam Ekran Kareleri**: `$XDG_RUNTIME_DIR/omnisnap/screen-[name].png`
   - Başarılı seçimde: [[action-orchestration]] betiğindeki `cleanup` komutu (`rm -f`) tarafından silinir.
   - İptal durumunda: `RegionSelection.qml`'deki `onDismiss` sinyaliyle silinir.
2. **Kırpılmış Eylem Dosyaları**: `/tmp/omnisnap-edit-*.png`, `/tmp/omnisnap-ocr-*.png`, `/tmp/omnisnap-search-*.png`
   - Eylemi gerçekleştiren bash boru hattının son satırında (`rm -f "$TMPF"`) daima temizlenir.

## İlişkili Dokümanlar
- Yaşam döngüsü modları: [[execution-lifecycles]]
- Eylem boru hattı: [[action-orchestration]]
- Kenar koruma onarımı: [[screen-edge-inhibitor]]
