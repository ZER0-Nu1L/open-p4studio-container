#!/usr/bin/env bash
# Copyright 2026 Open P4 Studio Container contributors
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repository_root"

find ci -type f -name '*.sh' -print0 | xargs -0 -n1 bash -n
python3 -m py_compile \
    ci/release/render_manifest.py \
    ci/selftest/minimal-forward/test.py
python3 -m json.tool ci/selftest/ports.json >/dev/null
manifest=$(mktemp)
trap 'rm -f "$manifest"' EXIT
python3 ci/release/render_manifest.py \
    --image ghcr.io/zer0-nu1l/open-p4studio-container \
    --digest sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
    --release sde-9.13.4-tofino1-r1 \
    --versions ci/image/versions.env \
    --output "$manifest"
python3 -m json.tool "$manifest" >/dev/null
git diff --check
