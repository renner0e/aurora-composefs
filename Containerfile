FROM ghcr.io/ublue-os/aurora:testing AS base

FROM base AS builder

RUN --mount=type=cache,dst=/var/cache/libdnf5 \
  dnf config-manager setopt keepcache=1 && \
  dnf -y builddep bootc

ENV CARGO_HOME=/var/cache/rust
ENV RUSTUP_HOME=/var/cache/rust
ENV CARGO_TARGET_DIR=/var/cache/rust/target
WORKDIR /home/build

RUN git clone "https://github.com/bootc-dev/bootc.git" . && git checkout bb8fb41e39cbb8c68b6e602307854a57b58f693a

RUN --mount=type=cache,dst=/var/cache/rust \
  make bin install-all DESTDIR=/output

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
