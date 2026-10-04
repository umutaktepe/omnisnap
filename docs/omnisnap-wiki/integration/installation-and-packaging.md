# Kurulum ve Paketleme (Installation & Packaging)

Omnisnap, root/sudo yetkisine ihtiyaç duymadan doğrudan kullanıcı alanında (`$HOME/.local/`) çalıştırılabilecek hafiflikte tasarlanmıştır.

## Gereksinimler (Sistem Paketleri)
Omnisnap'in çalışması için sistemde şu standart CLI paketlerinin bulunması gerekir:

| Paket | Dağıtım Paket Adı (Arch/Fedora/Debian) | Omnisnap İçi Rolü |
| :--- | :--- | :--- |
| `quickshell` | `quickshell` (AUR / COPR / Source) | Wayland LayerShell QML motoru |
| `spectacle` | `spectacle` | Arka plan ekran dondurma motoru |
| `imagemagick` | `imagemagick` | Piksel kırpma ve OCR ön işleme |
| `wl-clipboard` | `wl-clipboard` | Wayland panosuna (`wl-copy`) aktarım |
| `libnotify` | `libnotify` | Masaüstü bildirimleri (`notify-send`) |
| `swappy` | `swappy` | Ekran çizim ve not ekleme aracı |
| `tesseract` | `tesseract` | Optik karakter tanıma (OCR) |
| `curl` & `jq` | `curl`, `jq` | Google Lens Uguu API yüklemesi |

## Kurulum Betiği: `install.sh`
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${OMNISNAP_BIN_TARGET:-$HOME/.local/bin}"
DESKTOP_TARGET="${OMNISNAP_DESKTOP_TARGET:-$HOME/.local/share/applications}"

mkdir -p "$BIN_DIR" "$DESKTOP_TARGET"

echo "Installing Omnisnap to $BIN_DIR..."
ln -sf "$SCRIPT_DIR/bin/omnisnap" "$BIN_DIR/omnisnap"
ln -sf "$SCRIPT_DIR/bin/omnisnap-edges" "$BIN_DIR/omnisnap-edges"

echo "Installing Desktop entry to $DESKTOP_TARGET..."
sed "s|Exec=omnisnap|Exec=$BIN_DIR/omnisnap|g" "$SCRIPT_DIR/omnisnap.desktop" > "$DESKTOP_TARGET/omnisnap.desktop"

echo "Omnisnap installed successfully!"
```

### Betiğin Yaptığı İşlemler:
1. `bin/omnisnap` ve `bin/omnisnap-edges` sembolik bağlarını (symlinks) kullanıcının `~/.local/bin` dizinine bağlar.
2. `omnisnap.desktop` dosyasındaki `Exec` yolunu mutlak yolla güncelleyerek `~/.local/share/applications` altına yazar.
3. Kullanıcı depoları güncellediğinde (`git pull`) sembolik bağlar sayesinde yeniden kurulum gerekmez.

## Test Doğrulaması
`tests/test_install.sh` test dosyası, izole geçici hedef dizinlerde (`OMNISNAP_BIN_TARGET` ve `OMNISNAP_DESKTOP_TARGET`) sembolik bağların sağlamlığını ve desktop dosyasının geçerliliğini test eder.

## Kaldırma (Uninstall)
Omnisnap'i sistemden kaldırmak için oluşturulan sembolik bağları ve desktop dosyasını silmek yeterlidir:
```bash
rm -f ~/.local/bin/omnisnap ~/.local/bin/omnisnap-edges ~/.local/share/applications/omnisnap.desktop
```

## İlişkili Dokümanlar
- Komut satırı kullanımı: [[cli-interface]]
- Test altyapısı: [[testing-harness]]
- Masaüstü kısayolları: [[desktop-and-shortcuts]]
