# Open P4 Studio Container

[![image](https://github.com/ZER0-Nu1L/open-p4studio-container/actions/workflows/image.yml/badge.svg)](https://github.com/ZER0-Nu1L/open-p4studio-container/actions/workflows/image.yml)

Reproducible, digest-addressed containers for compiling P4 programs and
running them against the Tofino 1 software model from
[`p4lang/open-p4studio`](https://github.com/p4lang/open-p4studio).

This is an independent community project. It is not an official Intel,
P4.org, or p4lang image. It does not contain hardware BSPs, Serdes drivers,
firmware, P4Insight, or private Intel RDC material and does not enable use on
physical Tofino hardware.

## Pinned toolchain

| Component | Version |
| --- | --- |
| Platform | `linux/amd64` |
| Base | Ubuntu 22.04, pinned by digest |
| Open P4 Studio / SDE | `9.13.4` |
| open-p4studio | `0e81a468930b6f29ddf7744250b472d709944dcc` |
| p4c | `8ffb734bd26231ea0715d4615edbd4d34143ab3f` |
| Target | Tofino 1 model |

The image includes the P4 compiler, BFRT/BF Runtime gRPC, PTF, the Tofino
model, `bf_switchd`, the standard launch scripts, and a built-in neutral
self-test. It does not contain source code from any consuming project.

## Image contract

```text
Image:       ghcr.io/zer0-nu1l/open-p4studio-container
SDE:         /opt/open-p4studio
SDE_INSTALL: /opt/open-p4studio/install
Self-test:   /usr/local/bin/open-p4studio-selftest
```

Published releases provide an `image-lock.json` containing the complete
`image@sha256:...` reference. Consumers should use that digest and treat tags
as discovery metadata only.

## Build locally

```bash
git clone --recurse-submodules \
  https://github.com/ZER0-Nu1L/open-p4studio-container.git
cd open-p4studio-container

docker build \
  --file ci/image/Dockerfile \
  --tag open-p4studio-container:selftest \
  .
```

The build is intentionally heavyweight. The upstream system check determines
the exact resource requirements; use a clean amd64 Linux host with ample RAM
and free disk space.

## Run the built-in validation

The self-test compiles two programs and starts the model twice:

1. `minimal_forward`, maintained here, validates external P4 compilation,
   BFRT programming, forwarding, packet rewrite, and table deletion/drop.
2. Upstream `tna_counter` and `DirectCounterTest` validate compatibility with
   the pinned open-p4studio example and PTF framework.

```bash
mkdir -p artifacts
docker run --rm --privileged \
  --volume "$PWD/artifacts:/artifacts" \
  open-p4studio-container:selftest \
  open-p4studio-selftest
```

`--privileged` is required for veth creation, huge pages, the model, and
`bf_switchd`. Do not run untrusted images with this permission.

## Releases and licensing

Release tags use `sde-9.13.4-tofino1-rN`. A release is created only after the
published digest is pulled on a fresh runner and passes both self-tests again.
Each release includes the digest lock, SPDX SBOM, license inventory, and test
logs.

The source repository is public, and the published GHCR package is currently
publicly pullable. That operational state is not a legal determination:
review the redistribution status of every included binary, particularly the
model, before mirroring or relying on anonymous pulls. See
[docs/licensing.md](docs/licensing.md) and [docs/releasing.md](docs/releasing.md).
