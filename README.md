# Omnisnap 📸

A blazing fast, modern screenshot tool for **KDE Plasma 6 (Wayland)** inspired by Caelestia.

## ✨ Features
- **Screen Freeze Mode**: Instantly freezes the screen on shortcut press without display delay.
- **Smart Dimming Overlay**: Highlights the selected region with a smooth, focused darkening effect.
- **Dynamic Cursor Guide**: Live pill tooltip showing mode and action hints right next to your cursor.
- **Interactive Toolbar**: Switch between Screenshot, Annotation, Google Lens, and OCR text recognition on the fly.
- **Annotate & Draw**: Instant hand-off to Swappy for arrows, blur, rectangles, and text.
- **OCR Text Extraction**: Extract text directly from the screen into your clipboard using Tesseract.
- **Google Lens Visual Search**: Search any image region immediately in your browser.
- **Zero-Latency Daemon Mode**: Supports background daemon via Quickshell IPC.

## 📦 Dependencies
Ensure the following packages are installed on your system (e.g. via `pacman`, `dnf`, or `apt`):
- `quickshell` (Wayland layer-shell QML framework)
- `spectacle` (KDE background screenshot backend)
- `imagemagick` (`magick` CLI for cropping & OCR preprocessing)
- `wl-clipboard` (`wl-copy` for Wayland clipboard)
- `libnotify` (`notify-send` for desktop notifications)
- `swappy` (for screenshot editing/annotations)
- `tesseract` (for OCR text recognition)
- `curl` & `jq` (for Google Lens upload)

## 🚀 Installation
```bash
git clone https://github.com/umutaktepe/omnisnap.git
cd omnisnap
./install.sh
```

Ensure `~/.local/bin` is in your `$PATH`.

## ⌨️ KDE Plasma 6 Shortcut Configuration
1. Open **System Settings -> Shortcuts**.
2. Click **Add New -> Command**.
3. Set name to `Omnisnap Snip` and command to `omnisnap region`.
4. Assign your preferred key shortcut (e.g., `Print` or `Meta + Shift + S`).

You can also add separate shortcuts for specific modes:
- `omnisnap edit` for instant annotation with Swappy
- `omnisnap ocr` for instant text recognition
- `omnisnap search` for instant Google Lens search
- `omnisnap full` for instant fullscreen capture

## ⚡ Daemon Mode (Optional)
To achieve zero-startup-latency screenshot capture:
```bash
omnisnap daemon
```
Or stop it anytime:
```bash
omnisnap stop
```
Check status:
```bash
omnisnap status
```

## 💡 Acknowledgements & Credits
Omnisnap's screen freeze architecture and overlay UX were inspired by:
- **[caelestia-kde](https://github.com/ladybug-me/caelestia-kde)** by [ladybug-me](https://github.com/ladybug-me)
- **[caelestia-dots/shell](https://github.com/caelestia-dots/shell)** by [soramanew](https://github.com/soramanew)

Sincere thanks to the Caelestia contributors for their pioneering work on Wayland LayerShell screenshot overlays and visual design in the Linux desktop ecosystem.

## 📄 License
This project is licensed under the GNU General Public License v3.0 (GPL-3.0) - see the [LICENSE](LICENSE) file for details.
