# fichero-linux-printer

CUPS driver for the AiYin D11s/FICHERO USB label printer: print 14 x 30 mm
labels (text, QR codes, barcodes) from any Linux application.

[![CI](https://github.com/krouis/fichero-linux-printer/actions/workflows/packages.yml/badge.svg)](https://github.com/krouis/fichero-linux-printer/actions/workflows/packages.yml)

One architecture-independent package for **Ubuntu 24.04, Debian 12 and Debian 13** (and
other Debian-based systems with CUPS 2.x). It only depends on distribution
packages: `python3`, `python3-usb`, `cups`, `cups-filters` and `ghostscript`.

## Install

Download the `.deb` and `SHA256SUMS` from
[Releases](https://github.com/krouis/fichero-linux-printer/releases/latest), then:

```sh
sha256sum -c SHA256SUMS
sudo apt install ./fichero-linux-printer_0.2.0-1_all.deb
```

Plug in the printer: like any other USB printer, a CUPS queue named
**FICHERO_D11s** is added automatically (a second printer gets
`FICHERO_D11s_<serial>`). Printers already connected during installation are
configured immediately. The default printer is never changed, and an existing
queue for the printer (renamed, paused, with custom options) is left as is.

## Print

Select **FICHERO D11s** in the print dialog, paper size **14 x 30 mm**,
landscape for a horizontal 30 x 14 mm design. From the command line:

```sh
lp -d FICHERO_D11s label.pdf
lp -d FICHERO_D11s -n 3 -o FicheroDensity=1 label.pdf   # 0 light, 1 medium, 2 dark
```

The printable width is 12 mm (96-dot head). Design labels in **pure black on
white**: pixels lighter than 50 % gray are left white; there is no dithering,
which keeps text and QR codes sharp. Jobs are limited to 32 MiB, 100 labels
and 20 copies.

If the printer is unplugged, the job is held: plug it in and release the job.
A USB failure while sending stops the queue instead of reprinting: inspect the
label, then `cupsenable FICHERO_D11s`. "Completed" means the data was sent; the
USB protocol does not report paper or cover status.

## Alignment

The printhead is not exactly centred on the label. The driver compensates by
default (measured on a D11s: design moved 0.5 mm up and 1 mm left, as seen on
a landscape label). Keep at least 2 mm of margin around important content:
the printhead cannot reach closer to the top edge.

If your labels still look off-centre, adjust in 1/8 mm steps (up to ±2 mm)
in the printer options or with:

```sh
sudo lpadmin -p FICHERO_D11s -o FicheroShiftUp=4 -o FicheroShiftRight=-8
```

`FicheroShiftUp` > 0 moves the print up, `FicheroShiftRight` < 0 moves it left
(landscape orientation). Queue settings are kept across package upgrades.

## How it works

```
application ─► CUPS filters (PDF, page selection, orientation, copies)
            ─► /usr/lib/cups/backend/fichero (runs as user lp)
                 Ghostscript: 203 dpi gray raster, 112 x 240 dots per label
                 threshold, crop the 1 mm side margins to the 96-dot head
                 PyUSB: AiYin raster command sequence, 256-byte paced writes
```

| File | Role |
|---|---|
| `resources/fichero` | CUPS backend (≈ 250 lines, Python standard library + PyUSB) |
| `resources/FICHERO-D11s.ppd` | Label size, density option, IEEE-1284 device ID |
| `resources/71-fichero-cups.rules` | USB access for CUPS (group `lp`) and the seat user; starts queue creation on plug-in |
| `resources/fichero-printer@.service` | Runs `autoconfig SERIAL` when the printer is plugged in |
| `resources/autoconfig` | Adds the CUPS queue unless one already exists for that printer |
| `resources/fichero.usb-quirks` | Hides the printer from CUPS's generic `usb://` backend, which cannot drive it |

The print command sequence is the one used over USB by
[fichero-printer](https://github.com/0xMH/fichero-printer); CI checks that the
backend sends exactly the same bytes as that library (pinned commit
`7948e58` of the [krouis fork](https://github.com/krouis/fichero-printer)).

## Remove

```sh
sudo apt remove fichero-linux-printer
```

Removal deletes the queues that use the `fichero://` backend (they cannot
print without it) and nothing else.

## Develop

```sh
sudo apt install python3-pytest python3-usb cups cups-filters ghostscript
python3 -m pytest -q tests          # fake USB device, real Ghostscript/CUPS rendering
sh scripts/build-deb.sh             # dist/fichero-linux-printer_VERSION-1_all.deb
sh scripts/test-deb.sh dist/*.deb debian:13     # lifecycle test in a disposable container
sh scripts/test-deb.sh dist/*.deb debian:12
sh scripts/test-deb.sh dist/*.deb ubuntu:24.04
```

The USB stream comparison test runs when fichero-printer and its dependencies
(`python3-pil python3-numpy python3-bleak`) are importable, for example with
`PYTHONPATH=/path/to/fichero-printer`. The lifecycle test installs the package
offline, simulates hotplug, checks queue preservation, upgrade, rendering as
user `lp`, remove and purge.

To release: update `VERSION` and `RELEASE_NOTES.md`, then push a `vX.Y.Z` tag.
CI builds, tests on Ubuntu 24.04, Debian 12 and Debian 13, and publishes the release.

## License

MIT. The printer protocol was reverse-engineered by the MIT-licensed
fichero-printer project by 0xMH and contributors.
