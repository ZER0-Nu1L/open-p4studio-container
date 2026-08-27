# syntax=docker/dockerfile:1.7

ARG UBUNTU_IMAGE=ubuntu:22.04@sha256:2edbbc5dc405e9612ba3584ce95480277e3eb374407b5505fe26f17df77c7dbc
FROM ${UBUNTU_IMAGE}

ARG SDE_VERSION=9.13.4
ARG OPEN_P4STUDIO_COMMIT=0e81a468930b6f29ddf7744250b472d709944dcc
ARG P4C_COMMIT=8ffb734bd26231ea0715d4615edbd4d34143ab3f
ARG IMAGE_PROFILE=tofino1-model-bfrt
ARG VCS_REF=unknown
ARG SOURCE_URL=https://github.com/ZER0-Nu1L/open-p4studio-container

LABEL org.opencontainers.image.title="Open P4 Studio Container" \
      org.opencontainers.image.description="Community Open P4 Studio SDE container for Tofino 1 model CI" \
      org.opencontainers.image.source="${SOURCE_URL}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.version="${SDE_VERSION}" \
      org.opencontainers.image.licenses="Apache-2.0 AND LicenseRef-Upstream-Components" \
      io.open-p4studio-container.profile="${IMAGE_PROFILE}" \
      io.open-p4studio-container.open-p4studio-commit="${OPEN_P4STUDIO_COMMIT}" \
      io.open-p4studio-container.p4c-commit="${P4C_COMMIT}" \
      io.open-p4studio-container.target="tofino1-model"

ENV DEBIAN_FRONTEND=noninteractive \
    SDE=/opt/open-p4studio \
    SDE_INSTALL=/opt/open-p4studio/install \
    PATH=/opt/open-p4studio/install/bin:${PATH} \
    PYTHONUNBUFFERED=1

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        git \
        iproute2 \
        iputils-ping \
        libssl-dev \
        netcat-openbsd \
        procps \
        python3 \
        python3-pip \
        sudo \
        util-linux \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/open-p4studio
COPY third_party/open-p4studio/ /opt/open-p4studio/
COPY ci/image/profile.yaml /tmp/open-p4studio-profile.yaml

# Invoke the Python CLI directly. The shell wrapper unconditionally probes the
# host kernel build directory before entering the profile command; that probe
# is not applicable because this image deliberately disables kernel modules.
RUN python3 ./p4studio profile apply --jobs "$(nproc)" /tmp/open-p4studio-profile.yaml \
    && test -x "$SDE_INSTALL/bin/bf_switchd" \
    && test -x "$SDE_INSTALL/bin/tofino-model" \
    && test -x "$SDE_INSTALL/bin/p4c" \
    && if ! test -e "$SDE_INSTALL/bin/bf-p4c"; then \
           ln -s "$SDE_INSTALL/bin/p4c" "$SDE_INSTALL/bin/bf-p4c"; \
       fi \
    && rm -rf \
        /opt/open-p4studio/build \
        /root/.cache \
        /tmp/* \
        /var/tmp/*

COPY ci/selftest/ /opt/open-p4studio-container/selftest/
RUN chmod +x /opt/open-p4studio-container/selftest/scripts/*.sh \
    && ln -s /opt/open-p4studio-container/selftest/scripts/selftest.sh \
        /usr/local/bin/open-p4studio-selftest

WORKDIR /workspace
CMD ["/bin/bash"]
