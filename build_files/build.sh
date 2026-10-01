#!/bin/bash

set -ouex pipefail

cp -avf "/ctx/system_files"/. /

cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak
dnf config-manager setopt keepcache=1 timeout=60

dnf -y copr enable rhcontainerbot/bootc
dnf -y copr disable rhcontainerbot/bootc

dnf do -y \
  --action install systemd-boot-unsigned \
  --action remove {kmod-,}v4l2loopback kmod-xone xone-kmod-common

# /ctx/kernel.sh

dnf do -y \
  --action install --from-repo copr:copr.fedorainfracloud.org:rhcontainerbot:bootc bootc \
  --action remove bootc

/ctx/post.sh
