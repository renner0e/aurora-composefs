FROM ghcr.io/ublue-os/aurora:testing AS base

FROM base AS builder

RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=cache,dst=/var/home \
  dnf config-manager setopt keepcache=1 && \
  dnf -y builddep bootc

ENV CARGO_HOME=/var/cache/rust
ENV RUSTUP_HOME=/var/cache/rust
WORKDIR /home/build

RUN git clone -b cfs-progress "https://github.com/cgwalters/bootc.git" .

RUN make bin install-all DESTDIR=/output

FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

FROM base AS system

COPY --from=builder /output /

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

RUN bootc container lint
