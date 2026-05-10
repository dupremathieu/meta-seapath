#!/bin/bash
# Copyright (C) 2021, RTE (http://www.rte-france.com)
# Copyright (C) 2026 Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0

# Boot-time update health check
# Uses a bootcount file on the ESP to implement A/B fallback.
# systemd-boot does not support 'tries' for Type #1 entries,
# so we manage the counter ourselves.

/usr/share/update/mount_boot.sh mount

BOOTCOUNT_FILE="/boot/.seapath-bootcount"
LOADER_CONF="/boot/loader/loader.conf"

# Check if there's an active boot counter (post-update boot)
if [ -f "${BOOTCOUNT_FILE}" ] ; then
    bootcount=$(cat "${BOOTCOUNT_FILE}")

    if ! /usr/share/update/check-health.sh ; then
        echo "Health check failed (attempt ${bootcount})" 1>&2

        if [ "${bootcount}" -le 1 ] ; then
            # Exhausted all attempts: fall back to the other slot
            echo "Boot attempts exhausted, falling back to previous slot" 1>&2
            rm -f "${BOOTCOUNT_FILE}"

            # Read current default and switch to the other slot
            current_default=$(grep '^default' "${LOADER_CONF}" | awk '{print $2}')
            if echo "${current_default}" | grep -q "slot-a" ; then
                sed -i "s/^default .*/default seapath-slot-b.conf/" "${LOADER_CONF}"
            else
                sed -i "s/^default .*/default seapath-slot-a.conf/" "${LOADER_CONF}"
            fi

            /usr/share/update/mount_boot.sh umount
            touch /var/log/update_failure
            reboot
            exit 1
        else
            # Decrement counter and try again
            echo "$((bootcount - 1))" > "${BOOTCOUNT_FILE}"
            echo "Decremented boot counter to $((bootcount - 1)), retrying..." 1>&2
            /usr/share/update/mount_boot.sh umount
            reboot
            exit 1
        fi
    else
        # Health check passed: commit the update
        echo "Update success"
        rm -f "${BOOTCOUNT_FILE}"
        rm -f /var/log/update_marker
        touch /var/log/update_success
    fi
fi

/usr/share/update/mount_boot.sh umount

if [ -f /var/log/update_marker ] ; then
    # The update failed (marker exists but no boot counter file)
    rm -f /var/log/update_marker
    touch /var/log/update_failure
fi
