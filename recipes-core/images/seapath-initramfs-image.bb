# Copyright (C) 2026 Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0

DESCRIPTION = "SEAPATH initramfs image for rootfs discovery and overlay setup"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit image

PACKAGE_INSTALL = " \
    base-files \
    base-passwd \
    bash \
    util-linux \
    util-linux-blkid \
    util-linux-findfs \
    util-linux-mount \
    e2fsprogs \
    e2fsprogs-mke2fs \
"

IMAGE_FEATURES = ""
IMAGE_LINGUAS = ""
IMAGE_FSTYPES = "cpio.gz"
INITRAMFS_FSTYPES = "cpio.gz"

IMAGE_ROOTFS_SIZE = "8192"
IMAGE_OVERHEAD_FACTOR = "1.0"

# Install our custom init script
install_init() {
    install -m 0755 ${THISDIR}/seapath-initramfs/init ${IMAGE_ROOTFS}/init
}
IMAGE_PREPROCESS_COMMAND:append = " install_init;"
