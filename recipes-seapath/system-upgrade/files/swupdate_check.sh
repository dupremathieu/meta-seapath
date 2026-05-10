#!/bin/bash
# Copyright (C) 2021, RTE (http://www.rte-france.com)
# Copyright (C) 2026 Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0

# Boot-time update health check for systemd-boot
# Checks if current boot slot has a tries counter set, and assesses
# system health to commit or roll back the update.

/usr/share/update/mount_boot.sh mount

# Read default entry from loader.conf
default_entry=$(grep '^default' /boot/loader/loader.conf | awk '{print $2}')

if [ -z "${default_entry}" ] ; then
    default_entry="seapath-slot-a.conf"
fi

# Check if the default entry has a tries counter (indicates post-update boot)
if grep -q "^tries " "/boot/loader/entries/${default_entry}" 2>/dev/null ; then
    if ! /usr/share/update/check-health.sh ; then
        echo "Update tests have failed" 1>&2
        echo "Rebooting to the last working state..."
        /usr/share/update/mount_boot.sh umount
        reboot
        exit 1
    else
        echo "Update success"
        # Remove tries counter to commit the update
        sed -i '/^tries /d' "/boot/loader/entries/${default_entry}"
        rm -f /var/log/update_marker
        /usr/share/update/switch_bootloader.sh disable
        touch /var/log/update_success
    fi
fi

/usr/share/update/mount_boot.sh umount

if [ -f /var/log/update_marker ] ; then
    # The update failed (marker exists but no active tries entry)
    rm -f /var/log/update_marker
    /usr/share/update/switch_bootloader.sh
    /usr/share/update/switch_bootloader.sh disable
    echo "Update have failed" 1>&2
    touch /var/log/update_failure
fi
