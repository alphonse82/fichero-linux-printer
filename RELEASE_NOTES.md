First release of **fichero-d11s-cups**, a personal, unofficial CUPS driver for the
AiYin D11s/FICHERO USB label printer (14 x 30 mm gap labels).
One package for **Ubuntu 24.04, Debian 12 and Debian 13**: `fichero-d11s-cups_0.1.0-1_all.deb`.

```sh
sha256sum -c SHA256SUMS
sudo apt install ./fichero-d11s-cups_0.1.0-1_all.deb
```

### Features

- **Automatic setup on plug-in**: the CUPS queue `FICHERO_D11s` is added when the
  printer is connected, like other USB printers.
- **Only distribution dependencies** (`python3-usb`, Ghostscript, CUPS); the package
  itself is about 12 KB and independent of the Python version.
- The backend renders labels with Ghostscript and sends them directly over USB;
  CI checks that the USB bytes match the fichero-printer library's print path.
- Labels are thresholded at 50 % gray (no dithering): design them in black.
- Alignment options `FicheroShiftUp` / `FicheroShiftRight` (1/8 mm steps) with
  calibrated defaults (+0.5 mm up, 1 mm left).
- The generic CUPS `usb://` backend no longer offers this printer.

### Validation and limits

Hardware-verified on Debian 13 (queue added on plug-in, centred text + QR label).
Ubuntu 24.04 and Debian 12 are tested in containers (install, hotplug script,
upgrade, rendering, removal); the backend sends the same USB bytes everywhere.
Keep at least 2 mm of margin: the printhead cannot reach closer to the top edge.

Inspired by krouis/fichero-linux-printer but independent from it; the two
packages conflict and cannot be installed together.
