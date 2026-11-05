One package for **Ubuntu 24.04, Debian 12 and Debian 13**: `fichero-linux-printer_0.2.0-1_all.deb`.

```sh
sha256sum -c SHA256SUMS
sudo apt install ./fichero-linux-printer_0.2.0-1_all.deb
```

### Changes since 0.1.0

- **Automatic setup on plug-in**: the CUPS queue `FICHERO_D11s` is added when the
  printer is connected, like other USB printers. `fichero-printer-setup` is gone.
- **Only distribution dependencies** (`python3-usb`, Ghostscript, CUPS): no bundled
  Python environment, package size down from 16 MB to about 12 KB, and no longer
  tied to one Python version.
- The backend renders with Ghostscript and sends the label itself; CI checks that
  the USB bytes are identical to fichero-printer's own print path.
- Labels are thresholded at 50 % gray (no contrast stretching): design them in black.
- The generic CUPS `usb://` backend no longer offers this printer.
- New alignment options `FicheroShiftUp` / `FicheroShiftRight` (1/8 mm steps), with
  calibrated defaults: the print was about 0.5 mm too low and 1 mm too far right.

Upgrading from 0.1.0 should keep an existing `FICHERO_USB` queue (same URI); this path is not yet tested.
Hardware-verified on Debian 13 (queue added on plug-in, centred text + QR label).
Ubuntu 24.04 and Debian 12 are tested in containers (install, hotplug script,
upgrade, rendering, removal); the backend sends the same USB bytes everywhere.
