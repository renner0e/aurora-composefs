FROM ghcr.io/ublue-os/aurora:testing AS base

FROM base AS builder

RUN --mount=type=cache,dst=/var/cache/libdnf5 <<EOF
dnf config-manager setopt keepcache=1
dnf -y builddep bootc
dnf -y install sccache
mkdir -p /var/cache/sccache
EOF

ENV CARGO_HOME=/var/cache/rust \
  RUSTUP_HOME=/var/cache/rust \
  RUSTC_WRAPPER=/usr/bin/sccache \
  SCCACHE_DIR=/var/cache/sccache \
  CARGO_INCREMENTAL=0
WORKDIR /home/build

RUN git clone "https://github.com/bootc-dev/bootc.git" .
# RUN git clone "https://github.com/bootc-dev/bootc.git" . && git checkout bb8fb41e39cbb8c68b6e602307854a57b58f693a

RUN --mount=type=cache,dst=/var/cache/sccache \
  --mount=type=cache,dst=/var/cache/rust/registry \
  --mount=type=cache,dst=/var/cache/rust/git \
  --mount=type=cache,dst=/home/build/target \
<<EOF
/bin/time -f '%E %C' make bin install-all DESTDIR=/output && \
sccache --show-stats
EOF

FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

FROM base AS system

COPY --from=builder /output /

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=tmpfs,dst=/var \
    /ctx/build.sh

RUN bootc container lint --no-truncate --fatal-warnings
