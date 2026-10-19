# Copyright (C) 2026, Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0

# Evaluation-only image: omit the Python OVS helper and the service requiring it.
# Keep Open vSwitch itself in the compilation workload.
IMAGE_INSTALL:remove = "python3-setup-ovs system-config-ovs"
IMAGE_INSTALL:append = " openvswitch"
