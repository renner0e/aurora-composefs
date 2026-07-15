#!/bin/bash

set -ouex pipefail

cp -avf "/ctx/system_files"/. /

dnf do \
  --action install -y systemd-boot-unsigned \
  --action upgrade -y --enablerepo=updates-testing --refresh bootc

mkdir -p /usr/lib/dracut/dracut.conf.d/
printf 'reproducible=yes\nhostonly=no\ncompress=zstd\nadd_dracutmodules+=" bootc "' | tee "/usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-container-build.conf"

# Temporarily patch /usr/lib/os-release to avoid the initramfs depending on the
# version number (which changes daily).
tmp_release_file=$(mktemp --tmpdir 'os-release-XXXXXXXXXX')
cp /usr/lib/os-release "${tmp_release_file}"
sed -Ei -e '/^(OSTREE_)?VERSION=/d' /usr/lib/os-release

export DRACUT_NO_XATTR=1
dracut -v --force "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)/initramfs.img"

cp "${tmp_release_file}" /usr/lib/os-release
rm "${tmp_release_file}"

# Relink rpm-ostree-base-db to rpmdb to ensure it correctly reflects the system
# image's rpmdb and doesn't carry over package info from the base image.
# See: https://github.com/coreos/rpm-ostree/issues/4554
# https://forge.fedoraproject.org/atomic/tracker/issues/82
for file in rpmdb.sqlite rpmdb.sqlite-shm rpmdb.sqlite-wal; do
    target="/usr/share/rpm/${file}"
    link_path="/usr/lib/sysimage/rpm-ostree-base-db/${file}"
    if [[ -f "${target}" && -f "${link_path}" ]]; then
        # Note, this needs to be a hardlink, not a symbolic link.
        ln -f "${target}" "${link_path}"
    fi
done

