#!/bin/bash
# Copyright (C) 2021, RTE (http://www.rte-france.com)
# Copyright (C) 2026 Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0
#
# Switch between SEAPATH systemd-boot default entries for A/B rootfs.
# Usage:
#   switch_bootloader.sh         - toggle default between slot-a and slot-b
#   switch_bootloader.sh disable - commit current boot (remove boot counter)

set -e

die()
{
    echo "$@" 1>&2
    exit 1
}

/usr/share/update/mount_boot.sh mount

current_default=$(grep '^default' /boot/loader/loader.conf | awk '{print $2}')

if [ -z "${current_default}" ] ; then
    current_default="seapath-slot-a.conf"
fi

if [ "$1" = "disable" ] ; then
    # Commit update: remove boot counter
    rm -f /boot/.seapath-bootcount
else
    # Toggle default
    if echo "${current_default}" | grep -q "slot-a" ; then
        new_default="seapath-slot-b.conf"
    else
        new_default="seapath-slot-a.conf"
    fi
    echo "Switching default from ${current_default} to ${new_default}"
    sed -i "s/^default .*/default ${new_default}/" /boot/loader/loader.conf
fi

/usr/share/update/mount_boot.sh umount
