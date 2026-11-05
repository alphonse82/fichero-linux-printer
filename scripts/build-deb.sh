#!/bin/sh
# Build the architecture-independent package (Ubuntu 24.04, Debian 12 and 13, ...).
# Needs only dpkg-deb; no network, no Python tooling, no root.
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo"
version=$(cat VERSION)
case "$version" in ''|*[!0-9.]*) echo 'VERSION must be numeric (X.Y.Z)' >&2; exit 1 ;; esac
out=${1:-"$repo/dist"}
mkdir -p "$out"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM
root="$work/root"
doc="$root/usr/share/doc/fichero-d11s-cups"
install -d "$root/DEBIAN" "$doc"
install -D -m 755 resources/fichero "$root/usr/lib/cups/backend/fichero"
install -D -m 755 resources/autoconfig "$root/usr/lib/fichero-d11s-cups/autoconfig"
install -D -m 644 resources/FICHERO-D11s.ppd "$root/usr/share/ppd/fichero/FICHERO-D11s.ppd"
install -D -m 644 resources/fichero.usb-quirks "$root/usr/share/cups/usb/fichero.usb-quirks"
install -D -m 644 resources/71-fichero-cups.rules "$root/usr/lib/udev/rules.d/71-fichero-cups.rules"
install -D -m 644 resources/fichero-printer@.service "$root/usr/lib/systemd/system/fichero-printer@.service"
install -m 644 LICENSE "$doc/copyright"
install -m 644 README.md "$doc/README.md"
install -m 755 packaging/debian/postinst packaging/debian/prerm packaging/debian/postrm "$root/DEBIAN/"
cat > "$root/DEBIAN/control" <<CONTROL
Package: fichero-d11s-cups
Version: $version-1
Architecture: all
Maintainer: Alphonse <ob_github@obconseil.eu>
Section: utils
Priority: optional
Installed-Size: $(du -sk "$root/usr" | cut -f1)
Depends: python3, python3-usb, cups (>= 2.4), cups (<< 3.0), cups-client, cups-filters, ghostscript
Conflicts: fichero-linux-printer
Homepage: https://github.com/alphonse82/fichero-linux-printer
Description: CUPS driver for AiYin D11s/FICHERO USB label printers
 Prints 14 x 30 mm gap labels (text, QR codes) from any application.
 Independent project; it conflicts with the separate fichero-linux-printer
 package because both drive the printer through a "fichero" CUPS backend.
 The CUPS queue is added automatically when the printer is plugged in.
CONTROL
deb="fichero-d11s-cups_${version}-1_all.deb"
dpkg-deb --root-owner-group --build "$root" "$out/$deb"
(cd "$out" && sha256sum "$deb" > SHA256SUMS)
