#!/bin/bash

set -ouex pipefail

cp -avf "/ctx/system_files"/. /

cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak
dnf config-manager setopt keepcache=1 timeout=60

dnf -y copr enable rhcontainerbot/bootc
dnf -y copr disable rhcontainerbot/bootc

dnf do -y \
  --action install systemd-boot-{unsigned,x64} \
  --action remove {kmod-,}v4l2loopback kmod-xone xone-kmod-common

# /ctx/kernel.sh

# /ctx/bootc-git.sh

cp -a /usr/lib/systemd/boot/efi/systemd-bootx64.efi{.signed,}

/ctx/post.sh
