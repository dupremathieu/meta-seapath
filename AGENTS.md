# AGENTS.md — meta-seapath

Yocto Project layer for building SEAPATH embedded Linux images (hypervisor, guest, flasher, observer).

## Architecture

- **Layer**: `meta-seapath`, compatible with `wrynose`, depends on `efi-secure-boot`
- **Machines**: `seapath-hypervisor` (x86 host), `seapath-vm` (x86 guest), `seapath-installer`, `seapath-observer`, `seapath-observer-rpi`
- **Distro configs** define the target personality: `seapath-host`, `seapath-guest`, `seapath-flash`, `seapath-observer`, `seapath-standalone-host`, `seapath-containers-host`
- **Image recipes** live under `recipes-core/images/` — composed via `require` of `.inc` files (not `inherit`)
- **Classes** under `classes/` and `classes/security/` — rootfs hardening, read-only overlay, QA checks, user provisioning
- **Tests** use [Cukinia](https://github.com/savoirfairelinux/cukinia) — config files in `recipes-cukinia-tests/cukinia-tests/files/`
- **WiC kickstarts** live in `wic/`

## Important `DISTRO_FEATURES` flags

These flags conditionally gate recipes and bbclass inheritance. Set in `conf/distro/seapath-common.inc`:

| Flag | Effect |
|------|--------|
| `seapath-clustering` | HA cluster (Corosync/Pacemaker/Ceph), pulls cluster recipes and tests |
| `seapath-security` | Security hardening (kernel config checks, PAM policies, read-only fs, hardened compilation) |
| `seapath-readonly` | Read-only rootfs via volatile-binds |
| `seapath-overlay` | Overlay fs on `/etc` and persistent data partition, init via `/sbin/init.sh` |
| `seapath-cockpit` | Cockpit web admin (gated by `SEAPATH_COCKPIT` variable) |
| `ansible` | Inject Ansible SSH key at build time |
| `kvm` | KVM host support |
| `ptest` | Install package tests |
| `pam` | PAM authentication |

Guest distro (`seapath-guest.conf`) explicitly removes `seapath-clustering`, `seapath-readonly`, `seapath-overlay`, `kvm`, and `virtualization`.

## Build targets (bitbake image names)

- `seapath-host-efi-image` — production hypervisor
- `seapath-host-efi-dbg-image` — debug hypervisor (with tools, tests)
- `seapath-host-efi-swu-image` — SWUpdate-based hypervisor
- `seapath-host-efi-test-image` — test hypervisor
- `seapath-guest-efi-image` — production guest VM
- `seapath-guest-efi-dbg-image` — debug guest VM
- `seapath-guest-efi-test-image` — test guest VM
- `seapath-flasher.bb` / `seapath-flasher-cpio.bb` — USB flasher images
- `seapath-observer-efi-image` — observer (x86)
- `seapath-observer-rpi-image` — observer (Raspberry Pi)

## Key conventions

- All recipes are Apache-2.0 licensed
- Kernel: `linux-mainline-rt` (default 6.12 for hypervisor), recipe files are versioned (`linux-mainline-rt_6.12.bb`), shared config in `.inc`
- Image feature composition: each image `.bb` `require`s several `.inc` files from `recipes-core/images/` — follow the same pattern for new images
- Cukinia test packages are sub-packages of `cukinia-tests` (e.g. `cukinia-tests-hypervisor`, `cukinia-tests-cluster`). Tests are installed to `/etc/cukinia/` and selected at runtime via the `cukinia` config file.
- `SCRIPTS/get-next-test-id` generates the next available `SEAPATH-NNNNN` test identifier
- Static UID/GID allocation: `conf/distro/include/passwd.uid` and `conf/distro/include/group.gid`
- CVE exclusion files: `${LAYERDIR}/recipes-kernel/linux/cve-exclusion-*.inc`

## CI workflows

CI does **not** run builds in this repo. This repo delegates to a main/seapath repo:

- **PRs** (`pr.yml` → `pr-delegation.yml`): exports PR metadata as artifact, then dispatches to main repo's `pr.yml`. PRs from forks require maintainer approval before the delegation runs.
- **Push** (`push.yml`): dispatches to main repo's `push.yml` on push to `wrynose` branch.
- **Manual build** (`ci-build-yocto.yaml`): full Yocto build, runs on self-hosted `seapath-yocto-builder` runner.

Branch: `wrynose` is the primary branch (not `main`/`master`).

## Commit rules

All commits must be signed off with `git commit -s` (Developer Certificate of Origin).

## Local development

There are no local lint/test commands. Development happens in a full Yocto environment using `repo` and `bitbake`. See the upstream [SEAPATH repo-manifest](https://github.com/seapath/repo-manifest) for the build setup.
