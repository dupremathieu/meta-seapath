#!/bin/bash
# Copyright (C) 2021, RTE (http://www.rte-france.com)
# Copyright (C) 2026 Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0

die()
{
    echo "$@" 1>&2
    exit 1
}

do_preinst()
{
    echo "Pre-Install:"

    if [ -f /var/log/update_success ]; then
        rm -f /var/log/update_success
    fi

    if [ -f /var/log/update_failure ]; then
        rm -f /var/log/update_failure
    fi

    if [ ! -L "/dev/upgradable_rootfs" ] ; then
        die "Could not find symbolic link /dev/upgradable_rootfs"
    fi

    rootfs_part=$(readlink -f /dev/upgradable_rootfs)

    # Make sure partition is unmounted
    if grep -q "$rootfs_part" /proc/mounts ; then
        umount -f "$rootfs_part" || die "Error when umounting $rootfs_part"
    fi

    # Labels can be deduced from static partitioning
    # New layout: p1=boot(ESP), p2=rootfs0(Slot A), p3=rootfs1(Slot B)
    part_num="${rootfs_part:(-1)}"

    if [[ "${part_num}" == "2" ]] ; then
        rootfs_label="rootfs0"
        slot="a"
    else
        rootfs_label="rootfs1"
        slot="b"
    fi

    if ! mkfs.ext4 -q -F "$rootfs_part" -L "$rootfs_label" ; then
        die "Error when formatting the root partition"
    fi
}

do_postinst()
{
    echo "Post-Install:"

    rootfs_part=$(readlink -f /dev/upgradable_rootfs)
    part_num="${rootfs_part:(-1)}"

    if [[ "${part_num}" == "2" ]] ; then
        slot="a"
        slot_label="rootfs0"
        old_slot="b"
    else
        slot="b"
        slot_label="rootfs1"
        old_slot="a"
    fi

    # Mount ESP
    /usr/share/update/mount_boot.sh mount || die "Could not mount ESP"

    # Mount updated rootfs (use writable tmpfs location)
    UPGRADE_MNT="/tmp/upgrade"
    mkdir -p "$UPGRADE_MNT"
    if ! mount "$rootfs_part" "$UPGRADE_MNT" ; then
        die "Could not mount updated rootfs"
    fi

    # Copy kernel and loader entries from updated rootfs to ESP
    # Kernel
    if [ -f "$UPGRADE_MNT/boot/bzImage" ] ; then
        cp "$UPGRADE_MNT/boot/bzImage" /boot/bzImage || die "Could not copy kernel"
    fi
    # Initramfs
    if [ -f "$UPGRADE_MNT/boot/initrd" ] ; then
        cp "$UPGRADE_MNT/boot/initrd" /boot/initrd || die "Could not copy initrd"
    fi

    # Loader entries (from updated rootfs)
    if [ -d "$UPGRADE_MNT/boot/loader/entries" ] ; then
        cp "$UPGRADE_MNT/boot/loader/entries/"*.conf /boot/loader/entries/ || \
            echo "Warning: no loader entries found in updated rootfs"
    fi

    umount "$UPGRADE_MNT"
    rmdir "$UPGRADE_MNT"

    # Set tries on the updated slot entry for boot counting
    # tries must be placed before the linux line (Boot Loader Spec requirement)
    updated_entry="/boot/loader/entries/seapath-slot-${slot}.conf"
    if [ -f "${updated_entry}" ] ; then
        sed -i '/^tries /d' "${updated_entry}"
        sed -i "/^linux /i tries 3" "${updated_entry}"
    fi

    # Set the updated slot as the default (systemd-boot reads default from loader.conf)
    # We avoid bootctl for EFI variable access; direct file editing is more reliable
    sed -i "s/^default .*/default seapath-slot-${slot}.conf/" /boot/loader/loader.conf || \
        die "Could not set default boot entry"

    /usr/share/update/mount_boot.sh umount

    touch /var/log/update_marker
}

case "$1" in
preinst)
    echo "call do_preinst"
    do_preinst
    ;;
postinst)
    echo "call do_postinst"
    do_postinst
    ;;
*)
    die "Incorrect command"
    ;;
esac
