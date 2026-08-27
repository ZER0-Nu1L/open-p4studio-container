#!/usr/bin/env bash
# Copyright 2026 Open P4 Studio Container contributors
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 IMAGE_REFERENCE" >&2
    exit 2
fi

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
source "$repository_root/ci/image/versions.env"
image_ref=$1

label() {
    docker inspect --format "{{ index .Config.Labels \"$1\" }}" "$image_ref"
}

[[ "$(label org.opencontainers.image.version)" == "$SDE_VERSION" ]]
[[ "$(label io.open-p4studio-container.profile)" == "$IMAGE_PROFILE" ]]
[[ "$(label io.open-p4studio-container.open-p4studio-commit)" == "$OPEN_P4STUDIO_COMMIT" ]]
[[ "$(label io.open-p4studio-container.p4c-commit)" == "$P4C_COMMIT" ]]
[[ "$(label io.open-p4studio-container.target)" == "tofino1-model" ]]

docker run --rm "$image_ref" bash -ceu '
    test "$SDE" = /opt/open-p4studio
    test "$SDE_INSTALL" = /opt/open-p4studio/install
    test -x "$SDE_INSTALL/bin/p4c"
    test -x "$SDE_INSTALL/bin/tofino-model"
    test -x "$SDE_INSTALL/bin/bf_switchd"
    test -x /usr/local/bin/open-p4studio-selftest
'

echo "Image contract verified for $image_ref"
