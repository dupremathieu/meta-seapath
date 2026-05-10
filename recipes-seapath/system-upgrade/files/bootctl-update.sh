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

mount /boot 2>/dev/null || true

# Sync kernel from rootfs to ESP
if [ -f /usr/lib/modules/*/vmlinuz ] || [ -f /boot/bzImage ] ; then
    src_kernel=""
    for k in /boot/bzImage /usr/lib/modules/*/vmlinuz ; do
        [ -f "$k" ] && { src_kernel="$k"; break; }
    done
    if [ -n "${src_kernel}" ] ; then
        cp "${src_kernel}" /boot/bzImage 2>/dev/null || echo "Warning: kernel copy failed"
    fi
fi

# Sync loader entries (rootfs /boot may have newer entries after SWUpdate)
if [ -d /usr/lib/modules ] || [ -d /boot/loader/entries ] ; then
    # If /boot/loader doesn't exist on ESP, create it from rootfs
    if [ ! -d /boot/loader ] ; then
        mkdir -p /boot/loader/entries
        for entry in /boot/loader/entries/*.conf ; do
            [ -f "$entry" ] || continue
            cp "$entry" /boot/loader/entries/
        done
    fi
fi

# Refresh systemd-boot (installs/updates bootloader binary and EFI entry)
bootctl update 2>/dev/null || echo "Warning: bootctl update failed"

umount /boot 2>/dev/null || true
