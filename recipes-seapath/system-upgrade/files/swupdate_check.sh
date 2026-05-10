#!/bin/bash
# Copyright (C) 2021, RTE (http://www.rte-france.com)
# Copyright (C) 2026 Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0

# Boot-time update health check for systemd-boot
# Replaces GRUB bootcount/grubenv mechanism with systemd-boot boot assessment

/usr/share/update/mount_boot.sh mount

# Check if the current boot entry has a tries counter set
# (indicates we just booted into an updated slot)
current_entry=$(bootctl list 2>/dev/null | awk '/current:/ {print $2}' | sed 's,$,,')

if grep -q "^tries " /boot/loader/entries/"${current_entry}" 2>/dev/null ; then
    if ! /usr/share/update/check-health.sh ; then
        echo "Update tests have failed" 1>&2
        echo "Rebooting to the last working state..."
        /usr/share/update/mount_boot.sh umount
        reboot
        exit 1
    else
        echo "Update success"
        # Mark boot as successful - resets tries counter
        bootctl || echo "bootctl success marker failed"
        rm -f /var/log/update_marker
        # Commit the new default, remove tries from old entry
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
