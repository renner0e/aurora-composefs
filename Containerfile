FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

FROM ghcr.io/ublue-os/akmods:main-45-7.2.6-300.fc45 AS akmods

FROM ghcr.io/ublue-os/aurora:testing

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=bind,from=akmods,src=/kernel-rpms,dst=/tmp/akmods \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=tmpfs,dst=/var \
    /ctx/build.sh

RUN bootc container lint --no-truncate --fatal-warnings
