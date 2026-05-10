#!/bin/bash
# Copyright (C) 2021, RTE (http://www.rte-france.com)
# Copyright (C) 2026 Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0
#
# Switch between SEAPATH systemd-boot entries for A/B rootfs.
# Usage:
#   switch_bootloader.sh         - switch active/passive slot default
#   switch_bootloader.sh disable - disable old slot entry, commit current

set -e

die()
{
    echo "$@" 1>&2
    exit 1
}

# Check if efivarfs is mounted
if ! grep -q /sys/firmware/efi/efivars /proc/mounts ; then
    mount -t efivarfs efivarfs /sys/firmware/efi/efivars
fi

# Mount ESP
/usr/share/update/mount_boot.sh mount

# Get current default and all entries
default_entry=$(bootctl list 2>/dev/null | awk '/default:/ {print $2}' | sed 's,$,,')

if [ -z "${default_entry}" ] ; then
    die "Could not determine default boot entry"
fi

if [ "$1" = "disable" ] ; then
    # Mark current boot as successful (removes tries count)
    bootctl || echo "bootctl success marker failed"
else
    # Switch default between slot-a and slot-b
    if echo "${default_entry}" | grep -q "slot-a" ; then
        new_default="seapath-slot-b.conf"
    else
        new_default="seapath-slot-a.conf"
    fi

    echo "Switching default from ${default_entry} to ${new_default}"
    if ! bootctl set-default "${new_default}" ; then
        die "Error switching default boot entry"
    fi
fi

/usr/share/update/mount_boot.sh umount
