#!/usr/bin/env bash
set -eoux pipefail

KERNEL_PKGS_ORIG=(kernel kernel-{core,modules,modules-core,modules-extra})

# removing them all at once is slower
for pkg in "${KERNEL_PKGS_ORIG[@]}"; do
  rpm --erase "${pkg}" --nodeps
done

# cleanup leftovers that are not covered by kernel-* packages for some reason
rm -rf /usr/lib/modules

# shims to bypass kernel install triggering dracut/rpm-ostree
# this is really ugly, skipping scriplets might be not a good idea
cd /usr/lib/kernel/install.d \
&& mv 05-rpmostree.install 05-rpmostree.install.bak \
&& mv 50-dracut.install 50-dracut.install.bak \
&& printf '%s\n' '#!/bin/sh' 'exit 0' > 05-rpmostree.install \
&& printf '%s\n' '#!/bin/sh' 'exit 0' > 50-dracut.install \
&& chmod +x  05-rpmostree.install 50-dracut.install

dnf5 config-manager setopt coprdep:copr.fedorainfracloud.org:group_kernel-vanilla:mainline-wo-mergew.enabled=1

dnf -y install "${KERNEL_PKGS_ORIG[@]}"

# restore original kernel install
mv -f 05-rpmostree.install.bak 05-rpmostree.install \
&& mv -f 50-dracut.install.bak 50-dracut.install
cd -

