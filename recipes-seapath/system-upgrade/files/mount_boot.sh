#!/bin/bash
# Copyright (C) 2021, RTE (http://www.rte-france.com)
# Copyright (C) 2024 Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0

# Mount or unmount the /boot partition (ESP)
# ESP is always partition 1 (shared across both slots)
# Usage: mount-boot.sh [mount|umount]

rootfs_part=$(mount | awk '/\/ / { print $1 }')
disk_name="${rootfs_part: : -1}"
bootloader_part="${disk_name}1"

if [[ -z "$1" || "$1" == "mount"  ]] ; then
    # Unmount any stale mount first, then remount
    umount /boot 2>/dev/null || true
    mount "${bootloader_part}" /boot 2>/dev/null
elif [[ "$1" == "umount" ]] ; then
    umount /boot
fi
