# Copyright (C) 2026 Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0

DESCRIPTION = "SEAPATH initramfs image for rootfs discovery and overlay setup"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

FILESEXTRAPATHS:prepend := "${THISDIR}/seapath-initramfs:"

SRC_URI = "file://init"

PACKAGE_INSTALL = " \
    base-files \
    base-passwd \
    busybox \
    util-linux-blkid \
    util-linux-findfs \
    util-linux-mount \
    e2fsprogs \
"

IMAGE_FEATURES = ""
IMAGE_LINGUAS = ""
IMAGE_FSTYPES = "cpio.gz"
INITRAMFS_FSTYPES = "cpio.gz"

IMAGE_ROOTFS_SIZE = "8192"
IMAGE_OVERHEAD_FACTOR = "1.0"

# Do not pollute the initramfs image with rootfs features
SKIP_FEATURE_remove = "empty-root-password debug-tweaks read-only-rootfs"

BAD_RECOMMENDATIONS += "busybox-syslog"

# Install our custom init script
install_init() {
    install -m 0755 ${UNPACKDIR}/init ${IMAGE_ROOTFS}/init
}
IMAGE_PREPROCESS_COMMAND += "install_init;"
