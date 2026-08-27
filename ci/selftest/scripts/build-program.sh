#!/usr/bin/env bash
# Copyright 2026 Open P4 Studio Container contributors
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 PROGRAM_NAME P4_PATH BUILD_ROOT ARTIFACT_ROOT" >&2
    exit 2
fi

program_name=$1
p4_path=$2
build_root=$3
artifact_root=$4
build_dir="$build_root/$program_name"
program_artifacts="$artifact_root/$program_name"

: "${SDE:?SDE must be set}"
: "${SDE_INSTALL:?SDE_INSTALL must be set}"

rm -rf -- "$build_dir"
mkdir -p "$build_dir" "$program_artifacts"

cmake \
    -S "$SDE/p4studio" \
    -B "$build_dir" \
    -DCMAKE_MODULE_PATH="$SDE/cmake" \
    -DCMAKE_INSTALL_PREFIX="$SDE_INSTALL" \
    -DP4C="$SDE_INSTALL/bin/bf-p4c" \
    -DP4_PATH="$p4_path" \
    -DP4_NAME="$program_name" \
    -DP4_LANG=p4-16 \
    -DTOFINO=ON \
    -DTOFINO2=OFF \
    -DTOFINO2M=OFF \
    -DTOFINO3=OFF \
    -DTHRIFT-DRIVER=OFF \
    -DWITHPD=OFF \
    2>&1 | tee "$program_artifacts/cmake.log"

cmake --build "$build_dir" \
    --target install \
    --parallel "${BUILD_JOBS:-$(nproc)}" \
    2>&1 | tee "$program_artifacts/build.log"

conf="$SDE_INSTALL/share/p4/targets/tofino/$program_name.conf"
runtime_dir="$SDE_INSTALL/share/tofinopd/$program_name"
test -f "$conf"
test -f "$runtime_dir/bf-rt.json"
find "$runtime_dir" -type f -name context.json -print -quit | grep -q .
find "$runtime_dir" -type f -name tofino.bin -print -quit | grep -q .

while IFS= read -r file; do
    relative=${file#"$SDE_INSTALL"/}
    destination="$program_artifacts/generated/$relative"
    mkdir -p "$(dirname "$destination")"
    cp "$file" "$destination"
done < <(
    {
        printf '%s\n' "$conf"
        find "$runtime_dir" -type f \( -name '*.json' -o -name '*.conf' \)
    } | sort -u
)

find "$program_artifacts/generated" -type f -print0 \
    | sort -z \
    | xargs -0 sha256sum > "$program_artifacts/generated.sha256"
