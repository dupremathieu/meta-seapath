#!/bin/bash
# Copyright (C) 2021, RTE (http://www.rte-france.com)
# Copyright (C) 2026 Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0
#
# Switch between SEAPATH systemd-boot default entries for A/B rootfs.
# Edits loader.conf directly (avoids EFI variable dependency).
# Usage:
#   switch_bootloader.sh         - toggle default between slot-a and slot-b
#   switch_bootloader.sh disable - commit current boot by removing tries

set -e

die()
{
    echo "$@" 1>&2
    exit 1
}

# Mount ESP
/usr/share/update/mount_boot.sh mount

# Read current default from loader.conf
current_default=$(grep '^default' /boot/loader/loader.conf | awk '{print $2}')

if [ -z "${current_default}" ] ; then
    current_default="seapath-slot-a.conf"
fi

if [ "$1" = "disable" ] ; then
    # Commit current boot: remove tries from current default entry
    if [ -f "/boot/loader/entries/${current_default}" ] ; then
        sed -i '/^tries /d' "/boot/loader/entries/${current_default}"
    fi
else
    # Toggle default between slot-a and slot-b
    if echo "${current_default}" | grep -q "slot-a" ; then
        new_default="seapath-slot-b.conf"
    else
        new_default="seapath-slot-a.conf"
    fi

    echo "Switching default from ${current_default} to ${new_default}"
    sed -i "s/^default .*/default ${new_default}/" /boot/loader/loader.conf
fi

/usr/share/update/mount_boot.sh umount
