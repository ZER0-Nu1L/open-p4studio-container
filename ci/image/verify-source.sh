#!/usr/bin/env bash
# Copyright 2026 Open P4 Studio Container contributors
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
source "$repository_root/ci/image/versions.env"

artifact_dir=${1:-$repository_root/artifacts/source}
upstream_dir="$repository_root/third_party/open-p4studio"
compiler_dir="$upstream_dir/pkgsrc/p4-compilers/p4c"
mkdir -p "$artifact_dir"

actual_upstream=$(git -C "$upstream_dir" rev-parse HEAD)
actual_p4c=$(git -C "$compiler_dir" rev-parse HEAD)

[[ "$actual_upstream" == "$OPEN_P4STUDIO_COMMIT" ]] || {
    echo "open-p4studio commit mismatch: $actual_upstream" >&2
    exit 1
}
[[ "$actual_p4c" == "$P4C_COMMIT" ]] || {
    echo "p4c commit mismatch: $actual_p4c" >&2
    exit 1
}

for source_tree in "$upstream_dir" "$compiler_dir"; do
    dirty=$(git -C "$source_tree" status \
        --porcelain=v1 --untracked-files=all --ignore-submodules=none)
    ignored=$(git -C "$source_tree" ls-files \
        --others --ignored --exclude-standard)
    if [[ -n "$dirty" || -n "$ignored" ]]; then
        echo "Pinned source tree contains local, generated, or ignored files:" >&2
        printf '%s\n%s\n' "$dirty" "$ignored" >&2
        exit 1
    fi
done

expected_hw_files=$'RDC_README\nrdc_setup.sh'
actual_hw_files=$(find "$upstream_dir/hw" -type f -printf '%P\n' | sort)
if [[ "$actual_hw_files" != "$expected_hw_files" ]]; then
    echo "Unexpected file under upstream hw/; private RDC material is forbidden" >&2
    printf '%s\n' "$actual_hw_files" >&2
    exit 1
fi

rdc_only_paths=(
    pkgsrc/bf-drivers/src/alphawave
    pkgsrc/bf-drivers/src/credo
    pkgsrc/bf-drivers/src/avago
    pkgsrc/bf-drivers/src/microp
    pkgsrc/bf-drivers/src/port_mgr/csr
    pkgsrc/bf-drivers/src/port_mgr/crdo
    pkgsrc/bf-drivers/src/port_mgr/aw-gen
    pkgsrc/bf-drivers/src/port_mgr/t3-csr
    pkgsrc/bf-drivers/src/port_mgr/port_mgr_tof3/aw-reg-gen
    pkgsrc/bf-drivers/src/port_mgr/port_mgr_tof3/aw_16ln
    pkgsrc/bf-drivers/src/port_mgr/port_mgr_tof3/aw_4ln
    pkgsrc/bf-drivers/include/avago/aapl.h
    pkgsrc/bf-drivers/include/avago/avago_aapl.h
    pkgsrc/bf-drivers/include/avago/avago_dox.h
)
for relative_path in "${rdc_only_paths[@]}"; do
    if [[ -e "$upstream_dir/$relative_path" ]]; then
        echo "Private RDC-only path is forbidden: $relative_path" >&2
        exit 1
    fi
done

if compgen -G "$upstream_dir/pkgsrc/bf-drivers/libavago*" >/dev/null; then
    echo "Private RDC-only libavago material is forbidden" >&2
    exit 1
fi

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
