# Copyright (C) 2026, Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0

# Evaluation-only: host_efi omits system-config-ovs together with its helper.
# Do not pull the omitted helper into the build through this unused subpackage.
RDEPENDS:${PN}-ovs:remove = "python3-setup-ovs"
