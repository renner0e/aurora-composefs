#!/bin/bash

set -ouex pipefail

cp -avf "/ctx/system_files"/. /

dnf install -y systemd-boot-unsigned

mkdir -p /usr/lib/dracut/dracut.conf.d/
printf 'reproducible=yes\nhostonly=no\ncompress=zstd\nadd_dracutmodules+=" bootc "' | tee "/usr/lib/dracut/dracut.conf.d/30-bootcrew-bootc-container-build.conf"
dracut -v --force "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)/initramfs.img"

