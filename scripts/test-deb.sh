#!/bin/sh
# Package lifecycle test in a disposable Docker container, never on the host.
# Usage: sh scripts/test-deb.sh dist/PACKAGE.deb [IMAGE]   (default ubuntu:24.04)
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
deb=$(realpath "${1:?Pass the .deb path}")
image=${2:-ubuntu:24.04}
# With Docker's unlimited open-file limit, Ubuntu's cupsd 2.4.7 fails at startup
# ("cupsdDoSelect() failed - Bad address"): use an ordinary limit.
# Hide the host's USB bus (visible through /sys), so a printer plugged into the
# host does not change the results.
container=$(docker create --ulimit nofile=65536:65536 \
    --mount type=tmpfs,destination=/sys/bus/usb "$image" sleep infinity)
trap 'docker rm -f "$container" >/dev/null' EXIT HUP INT TERM
docker start "$container" >/dev/null
docker cp "$deb" "$container:/tmp/package.deb"
docker cp "$repo/packaging/test-installed.sh" "$container:/tmp/test-installed.sh"
# Download the package's dependencies only; installation then happens offline.
docker exec -e DEBIAN_FRONTEND=noninteractive "$container" sh -c '
    apt-get update -qq
    apt-get install -y -qq --no-install-recommends --download-only /tmp/package.deb >/dev/null
'
docker network disconnect bridge "$container"
docker exec -e DEBIAN_FRONTEND=noninteractive "$container" sh /tmp/test-installed.sh
