#!/usr/bin/env bash
# Copyright 2026 Open P4 Studio Container contributors
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
source "$repository_root/ci/image/versions.env"

artifact_dir=${1:-$repository_root/artifacts/source}
upstream_dir="$repository_root/third_party/open-p4studio"
mkdir -p "$artifact_dir"

actual_upstream=$(git -C "$upstream_dir" rev-parse HEAD)
actual_p4c=$(git -C "$upstream_dir/pkgsrc/p4-compilers/p4c" rev-parse HEAD)

[[ "$actual_upstream" == "$OPEN_P4STUDIO_COMMIT" ]] || {
    echo "open-p4studio commit mismatch: $actual_upstream" >&2
    exit 1
}
[[ "$actual_p4c" == "$P4C_COMMIT" ]] || {
    echo "p4c commit mismatch: $actual_p4c" >&2
    exit 1
}

grep -Fq "project(p4factory VERSION $SDE_VERSION" \
    "$upstream_dir/CMakeLists.txt"

required_files=(
    LICENSE
    ThirdPartyNotice.txt
    LICENSES/Apache-2.0.txt
    LICENSES/GPL-2.0-or-later.txt
    pkgsrc/tofino-model/README.md
)

inventory="$artifact_dir/license-inventory.sha256"
: > "$inventory"
for relative_path in "${required_files[@]}"; do
    file="$upstream_dir/$relative_path"
    [[ -f "$file" ]] || {
        echo "Required upstream license material is missing: $relative_path" >&2
        exit 1
    }
    digest=$(sha256sum "$file" | awk '{print $1}')
    printf '%s  %s\n' "$digest" "$relative_path" >> "$inventory"
done

cat > "$artifact_dir/source-versions.txt" <<VERSIONS
image_name=$IMAGE_NAME
platform=$IMAGE_PLATFORM
profile=$IMAGE_PROFILE
sde_version=$SDE_VERSION
open_p4studio_commit=$actual_upstream
p4c_commit=$actual_p4c
base_image=$UBUNTU_IMAGE
VERSIONS

echo "Pinned source and license material verified."
