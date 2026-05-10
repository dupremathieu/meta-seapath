#!/bin/bash
# Copyright (C) 2021, RTE (http://www.rte-france.com)
# This program is distributed under the Apache 2 license.
#
# Script to be called from udev partition_symlinks.rules in order to
# symlink the inactive rootfs partition. The symlink can be later used
# to flash the inactive bank.
#
# Disk partitions are static:
# - Slot A: rootfs on /dev/<disk>2 (label rootfs0)
# - Slot B: rootfs on /dev/<disk>3 (label rootfs1)
#
# This script takes two positional arguments:
# - The first one indicates which type of partition to check.
#   Only 'rootfs' is supported.
# - The second one is the partition name to verify, i.e., '/dev/sda2'.
#
# The script echoes '1' if parameters correspond to the inactive bank
# or '0' otherwise.

if [[ "$#" -ne 2 ]] ; then
    echo "Script requires two arguments"
    exit 1
fi

if [[ "${1}" != "bootloader" && "${1}" != "rootfs" ]] ; then
    echo "Invalid first argument"
    exit 1
fi

# Get disk name and partition num for current mounted rootfs
rootfs_part=$(mount | awk '/\/ / { print $1 }')
disk_name="${rootfs_part: : -1}"
part_num="${rootfs_part:(-1)}"

# Deduce inactive bank partitions (static association)
# New layout: p1=boot, p2=rootfs0 (Slot A), p3=rootfs1 (Slot B)
if [[ "${part_num}" == "2" ]] ; then
    inactive_rootfs_p="${disk_name}3"
else
    inactive_rootfs_p="${disk_name}2"
fi

# Verify if parameters correspond to type and name of current inactive partition
# Bootloader is now shared (always p1), no inactive bootloader detection needed.
# Keep 'bootloader' argument for backward compat but always return 0.
if [[ "${1}" == "rootfs" && "${2}" == "${inactive_rootfs_p}" ]] ; then
    echo 1
else
    echo 0
fi
