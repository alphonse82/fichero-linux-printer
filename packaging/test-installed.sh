#!/bin/sh
# Destructive lifecycle tests: only run inside the disposable test container.
set -eu
[ -f /.dockerenv ] || { echo 'Refusing to test package lifecycle on the host' >&2; exit 1; }
server=/run/cups/cups.sock
step() { printf '\n=== %s\n' "$*"; }
queue_for() { LC_ALL=C lpstat -h "$server" -v | awk -v u="fichero://usb?serial=$1" '$NF == u { sub(/:$/, "", $3); print $3 }'; }
autoconfig=/usr/lib/fichero-linux-printer/autoconfig

step 'Install with apt, offline, before CUPS is running (dependencies resolved from Depends)'
apt-get install -y -qq --no-install-recommends /tmp/package.deb
mkdir -p /run/cups && /usr/sbin/cupsd
tries=50
until [ "$(LC_ALL=C lpstat -h "$server" -r)" = 'scheduler is running' ]; do
    tries=$((tries - 1)); [ "$tries" -gt 0 ] || { echo 'cupsd did not start' >&2; exit 1; }
    sleep 0.2
done
lpadmin -h "$server" -p KEEP_ME -E -v socket://127.0.0.1:9 -m raw
lpadmin -h "$server" -d KEEP_ME
cupstestppd -q /usr/share/ppd/fichero/FICHERO-D11s.ppd
grep -q '^0x09c5 0x0200 blacklist' /usr/share/cups/usb/fichero.usb-quirks

step 'Hotplug: first printer gets FICHERO_D11s, nothing else changes'
$autoconfig EXAMPLE123
[ "$(queue_for EXAMPLE123)" = FICHERO_D11s ]
lpoptions -h "$server" -p FICHERO_D11s -l | grep -q 'PageSize.*\*14x30mm'
LC_ALL=C lpstat -h "$server" -d | grep -q KEEP_ME
if $autoconfig 'BAD;SERIAL' 2>/dev/null; then exit 1; fi

step 'Replug: an existing queue is kept as is (paused, options, renamed)'
cupsdisable -h "$server" FICHERO_D11s
lpadmin -h "$server" -p FICHERO_D11s -o FicheroDensity=1
$autoconfig EXAMPLE123
[ "$(queue_for EXAMPLE123 | wc -l)" = 1 ]
LC_ALL=C lpstat -h "$server" -p FICHERO_D11s | grep -q disabled
lpoptions -h "$server" -p FICHERO_D11s -l | grep -q 'FicheroDensity.*\*1'

step 'A second printer gets its own queue'
$autoconfig OTHER456
[ "$(queue_for OTHER456)" = FICHERO_D11s_OTHER456 ]

step 'Backend and renderer run offline as CUPS user lp'
discovery=$(runuser -u lp -- /usr/lib/cups/backend/fichero 2>&1)  # Must start and exit 0.
[ -z "$discovery" ]  # No printer connected: lists nothing, no error.
cat > /tmp/label.ps <<'PS'
%!PS
<< /PageSize [39.685039 85.039370] >> setpagedevice
0 setgray 10 20 20 40 rectfill showpage
PS
gs -q -dSAFER -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=/tmp/label.pdf /tmp/label.ps
chmod 644 /tmp/label.pdf
status=0
runuser -u lp -- env DEVICE_URI='fichero://usb?serial=EXAMPLE123' \
    /usr/lib/cups/backend/fichero 1 user title 1 '' /tmp/label.pdf 2>/tmp/backend.log || status=$?
cat /tmp/backend.log
[ "$status" = 3 ]  # Rendered, then held because no printer is connected.
grep -q 'not connected' /tmp/backend.log

step 'Upgrade keeps the queues and their settings'
dpkg-deb -R /tmp/package.deb /tmp/upgrade
sed -i '/^Version:/s/$/+test1/' /tmp/upgrade/DEBIAN/control
dpkg-deb --root-owner-group --build /tmp/upgrade /tmp/upgrade.deb >/dev/null
dpkg -i /tmp/upgrade.deb
LC_ALL=C lpstat -h "$server" -p FICHERO_D11s | grep -q disabled
lpoptions -h "$server" -p FICHERO_D11s -l | grep -q 'FicheroDensity.*\*1'

step 'Remove deletes only fichero queues; purge leaves nothing'
dpkg --remove fichero-linux-printer
[ -z "$(LC_ALL=C lpstat -h "$server" -v | grep fichero: || true)" ]
LC_ALL=C lpstat -h "$server" -d | grep -q KEEP_ME
test ! -e /usr/lib/cups/backend/fichero
dpkg --purge fichero-linux-printer
test ! -e /usr/lib/fichero-linux-printer

step 'Reinstall'
dpkg -i /tmp/package.deb
$autoconfig EXAMPLE123
[ "$(queue_for EXAMPLE123)" = FICHERO_D11s ]
dpkg --purge fichero-linux-printer
lpstat -h "$server" -p KEEP_ME >/dev/null

printf '\nInstall, hotplug queue creation, replug, upgrade, offline render as lp, remove, purge, reinstall: PASS\n'
