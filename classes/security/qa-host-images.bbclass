# Copyright (C) 2021, RTE (http://www.rte-france.com)
# SPDX-License-Identifier: Apache-2.0

#
# QA checks to be performed on host images prior building
# the image.
# Those checks shall return 0 on success and >0 on failure.
#
# Any check failure will stop the build.
#

require qa-common.inc

systemd_boot_is_setup_properly() {
    check_systemd_boot
}

IMAGE_QA_COMMANDS += "              \
    systemd_boot_is_setup_properly \
    verify_secureboot_signature   \
"
