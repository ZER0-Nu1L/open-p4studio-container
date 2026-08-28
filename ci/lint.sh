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
temporary_dir=$(mktemp -d)
trap 'rm -rf "$temporary_dir"' EXIT
manifest="$temporary_dir/image-lock.json"
python3 ci/release/render_manifest.py \
    --image ghcr.io/zer0-nu1l/open-p4studio-container \
    --digest sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
    --release sde-9.13.4-tofino1-r1 \
    --source-repository https://github.com/ZER0-Nu1L/open-p4studio-container \
    --container-commit bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb \
    --versions ci/image/versions.env \
    --output "$manifest"
python3 -m json.tool "$manifest" >/dev/null
python3 - "$manifest" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as manifest_file:
    manifest = json.load(manifest_file)

assert manifest["schema_version"] == 1
assert manifest["container_commit"] == "b" * 40
assert manifest["source_repository"] == (
    "https://github.com/ZER0-Nu1L/open-p4studio-container"
)
PY

tag_repository="$temporary_dir/tag-repository"
git init --quiet "$tag_repository"
git -C "$tag_repository" config user.email ci@example.invalid
git -C "$tag_repository" config user.name "CI fixture"
printf 'fixture\n' > "$tag_repository/fixture.txt"
git -C "$tag_repository" add fixture.txt
git -C "$tag_repository" commit --quiet -m fixture
git -C "$tag_repository" update-ref refs/remotes/origin/main HEAD
git -C "$tag_repository" tag --annotate sde-9.13.4-tofino1-r999 \
    --message fixture \
    --message 'Publication-Review: approved-public'
REPOSITORY_ROOT="$tag_repository" \
VERSIONS_FILE="$repository_root/ci/image/versions.env" \
ci/release/validate_tag.sh \
    sde-9.13.4-tofino1-r999 refs/remotes/origin/main \
    > "$temporary_dir/tag-output"
grep -Fxq 'tag=sde-9.13.4-tofino1-r999' "$temporary_dir/tag-output"
grep -Eq '^container_commit=[0-9a-f]{40}$' "$temporary_dir/tag-output"

git -C "$tag_repository" tag sde-9.13.4-tofino1-r998
if REPOSITORY_ROOT="$tag_repository" \
    VERSIONS_FILE="$repository_root/ci/image/versions.env" \
    ci/release/validate_tag.sh \
    sde-9.13.4-tofino1-r998 refs/remotes/origin/main >/dev/null 2>&1; then
    echo "Lightweight release tag unexpectedly passed validation" >&2
    exit 1
fi
git diff --check
