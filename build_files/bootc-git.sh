#!/usr/bin/env bash
set -eoux pipefail

dnf do -y \
  --action install --from-repo copr:copr.fedorainfracloud.org:rhcontainerbot:bootc bootc \
  --action remove bootc
