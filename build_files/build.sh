#!/bin/bash

set -ouex pipefail

cp -avf "/ctx/system_files"/. /

cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak
dnf config-manager setopt keepcache=1 timeout=60

dnf do \
  --action install -y systemd-boot-unsigned \
  --action upgrade -y --enablerepo=updates-testing --refresh bootc \
  --action remove -y v4l2loopback

# https://github.com/ublue-os/aurora/issues/2568
TMP_OS_RELEASE=$(mktemp --tmpdir 'os-release-XXXXXXXXXX')
cp /usr/lib/os-release "${TMP_OS_RELEASE}"
sed -Ei -e '/^((OSTREE_)?(IMAGE_)?VERSION|PRETTY_NAME|BUILD_ID)=/d' /usr/lib/os-release

DRACUT_NO_XATTR=1 /usr/bin/dracut \
  --verbose \
  --force \
  "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)/initramfs.img"

cp "${TMP_OS_RELEASE}" /usr/lib/os-release
rm "${TMP_OS_RELEASE}"

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

mv /etc/dnf/dnf.conf.bak /etc/dnf/dnf.conf
