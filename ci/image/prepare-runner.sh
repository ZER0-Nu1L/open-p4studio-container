#!/usr/bin/env bash
# Copyright 2026 Open P4 Studio Container contributors
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

if [[ "${GITHUB_ACTIONS:-false}" != "true" ]]; then
    echo "Runner cleanup is only performed on GitHub Actions."
    exit 0
fi

for path in \
    /usr/local/lib/android \
    /usr/share/dotnet \
    /opt/ghc \
    /usr/local/.ghcup \
    /opt/hostedtoolcache/CodeQL; do
    if [[ -e "$path" ]]; then
        sudo rm -rf -- "$path"
    fi
done

docker system prune --all --force --volumes || true
df -h
free -h
nproc
