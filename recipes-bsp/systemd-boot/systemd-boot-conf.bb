# Copyright (C) 2026 Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0

SUMMARY = "SEAPATH systemd-boot configuration"
DESCRIPTION = "Provides dual-slot (A/B) boot entries for systemd-boot"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "\
    file://loader.conf \
    file://seapath-slot-a.conf \
    file://seapath-slot-b.conf \
"

RPROVIDES:${PN} += "virtual-systemd-bootconf"
PACKAGE_ARCH = "${MACHINE_ARCH}"

S = "${WORKDIR}"

do_compile() {
    extra_append=""
    if ${@bb.utils.contains('MACHINE_FEATURES', 'seapath-guest', 'true', 'false', d)} ; then
        if [ "${SEAPATH_GUEST_DISABLE_IPV6}" = "true" ] ; then
            extra_append=" ipv6.disable=1"
        fi
    else
        if [ "${SEAPATH_DISABLE_IPV6}" = "true" ] ; then
            extra_append=" ipv6.disable=1"
        fi
    fi

    cp ${S}/seapath-slot-a.conf ${B}/seapath-slot-a.conf
    cp ${S}/seapath-slot-b.conf ${B}/seapath-slot-b.conf

    sed -e "s|^options .*|options ${APPEND}${extra_append} root=LABEL=rootfs0|" \
        -i ${B}/seapath-slot-a.conf
    sed -e "s|^options .*|options ${APPEND}${extra_append} root=LABEL=rootfs1|" \
        -i ${B}/seapath-slot-b.conf
}

do_compile:append:seapath-hypervisor() {
    if [ -n "${SEAPATH_RT_CORES}" ] ; then
        extra="isolcpus=${SEAPATH_RT_CORES} nohz_full=${SEAPATH_RT_CORES} rcu_nocbs=${SEAPATH_RT_CORES}"
        sed -i "s|^options |options ${extra} |" ${B}/seapath-slot-a.conf
        sed -i "s|^options |options ${extra} |" ${B}/seapath-slot-b.conf
    fi
}

do_install() {
    install -d ${D}/boot/loader
    install -d ${D}/boot/loader/entries
    install -m 0644 ${S}/loader.conf ${D}/boot/loader/loader.conf
    install -m 0644 ${B}/seapath-slot-a.conf ${D}/boot/loader/entries/
    install -m 0644 ${B}/seapath-slot-b.conf ${D}/boot/loader/entries/
}

FILES:${PN} = "/boot/loader/* /boot/loader/entries/*"
