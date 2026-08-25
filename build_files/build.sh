#!/bin/bash

set -ouex pipefail

cp -avf "/ctx/system_files"/. /

cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak
dnf config-manager setopt keepcache=1 timeout=60

dnf do \
  --action install -y systemd-boot-unsigned \
  --action remove -y {kmod-,}v4l2loopback

dnf -y copr enable egoode/dnf-rebuild
dnf -y copr disable egoode/dnf-rebuild
dnf -y distro-sync --from-repo copr:copr.fedorainfracloud.org:egoode:dnf-rebuild '*' --allow-vendor-change
dnf -y install --from-repo copr:copr.fedorainfracloud.org:egoode:dnf-rebuild dnf5-plugin-rebuild

dnf -y copr enable rhcontainerbot/bootc
dnf -y copr disable rhcontainerbot/bootc
dnf -y swap --from-repo copr:copr.fedorainfracloud.org:rhcontainerbot:bootc bootc bootc

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

/ctx/post.sh
