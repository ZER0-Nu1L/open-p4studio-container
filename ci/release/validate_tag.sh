#!/usr/bin/env bash
# Copyright 2026 Open P4 Studio Container contributors
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

tag_name=${1:?usage: validate_tag.sh TAG [MAIN_REF]}
main_ref=${2:-refs/remotes/origin/main}
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repository_root=${REPOSITORY_ROOT:-$(cd "$script_dir/../.." && pwd)}
versions_file=${VERSIONS_FILE:-$repository_root/ci/image/versions.env}

# shellcheck disable=SC1090
source "$versions_file"

target=${IMAGE_PROFILE%%-*}
expected_prefix="sde-${SDE_VERSION}-${target}"
revision=${tag_name#"$expected_prefix-r"}

if [[ "$tag_name" != "$expected_prefix-r$revision" ]] \
    || [[ ! "$revision" =~ ^[1-9][0-9]*$ ]]; then
    echo "Invalid release tag: $tag_name (expected ${expected_prefix}-rN)" >&2
    exit 1
fi

tag_ref="refs/tags/$tag_name"
object_type=$(git -C "$repository_root" cat-file -t "$tag_ref" 2>/dev/null || true)
if [[ "$object_type" != tag ]]; then
    echo "Release tag must be annotated: $tag_name" >&2
    exit 1
fi

if ! git -C "$repository_root" for-each-ref \
    --format='%(contents)' "$tag_ref" \
    | grep -Fqx 'Publication-Review: approved-public'; then
    echo "Release tag lacks Publication-Review: approved-public" >&2
    exit 1
fi

tag_commit=$(git -C "$repository_root" rev-parse "$tag_ref^{}")
if [[ $(git -C "$repository_root" cat-file -t "$tag_commit") != commit ]]; then
    echo "Release tag does not peel to a commit: $tag_name" >&2
    exit 1
fi

main_commit=$(git -C "$repository_root" rev-parse "$main_ref^{commit}")
if [[ "$tag_commit" != "$main_commit" ]]; then
    echo "Release tag target $tag_commit is not current $main_ref $main_commit" >&2
    exit 1
fi

printf 'tag=%s\n' "$tag_name"
printf 'container_commit=%s\n' "$tag_commit"
