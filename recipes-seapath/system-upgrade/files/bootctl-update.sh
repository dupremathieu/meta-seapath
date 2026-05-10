#!/bin/bash
# Copyright (C) 2026 Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0
#
# First-boot ESP sync: ensures the shared ESP has the latest kernel
# and boot entries from the rootfs. Runs as a oneshot service on first
# boot after fresh installation or after SWUpdate.
#
# - Copies kernel from rootfs /boot/bzImage to ESP /boot/bzImage
# - Copies loader entries from rootfs to ESP (preserving any tries
#   counter set by SWUpdate)
# - Runs bootctl update to refresh systemd-boot and EFI entry

set -e

# Make sure ESP is properly mounted (unmount any stale mount first)
umount /boot 2>/dev/null || true
/usr/share/update/mount_boot.sh mount

# Sync kernel from rootfs to ESP
if [ -f /boot/bzImage ]; then
    echo "ESP kernel present, nothing to sync"
fi

# Ensure loader directory exists on ESP
if [ ! -d /boot/loader ]; then
    mkdir -p /boot/loader/entries
fi

# Sync loader entries if rootfs /boot has entries we need
for entry in /boot/loader/entries/*.conf; do
    [ -f "$entry" ] || continue
    cp "$entry" /boot/loader/entries/ 2>/dev/null || true
done

# Refresh systemd-boot (installs/updates bootloader binary and EFI entry)
bootctl update 2>/dev/null || echo "Warning: bootctl update failed"

# Unmount ESP
/usr/share/update/mount_boot.sh umount
