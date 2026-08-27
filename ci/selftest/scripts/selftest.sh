#!/usr/bin/env bash
# Copyright 2026 Open P4 Studio Container contributors
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
    echo "The model self-test must run as root in a privileged container." >&2
    exit 1
fi

export SDE=${SDE:-/opt/open-p4studio}
export SDE_INSTALL=${SDE_INSTALL:-$SDE/install}
export PATH="$SDE_INSTALL/bin:$PATH"

selftest_root=${SELFTEST_ROOT:-/opt/open-p4studio-container/selftest}
artifact_root=${ARTIFACT_ROOT:-/artifacts}
build_root=${BUILD_ROOT:-/work/open-p4studio-selftest}
scripts="$selftest_root/scripts"
ports_file="$selftest_root/ports.json"

mkdir -p "$artifact_root" "$build_root"

"$scripts/build-program.sh" \
    minimal_forward \
    "$selftest_root/minimal-forward/minimal_forward.p4" \
    "$build_root" \
    "$artifact_root"

"$scripts/build-program.sh" \
    tna_counter \
    "$SDE/pkgsrc/p4-examples/p4_16_programs/tna_counter/tna_counter.p4" \
    "$build_root" \
    "$artifact_root"

"$SDE_INSTALL/bin/veth_setup.sh" 128 \
    >"$artifact_root/veth-setup.log" 2>&1

"$scripts/run-program.sh" \
    minimal_forward \
    "$selftest_root/minimal-forward" \
    "$ports_file" \
    "$artifact_root/minimal_forward" \
    test.MinimalForwardTest

"$scripts/run-program.sh" \
    tna_counter \
    "$SDE/pkgsrc/p4-examples/p4_16_programs/tna_counter" \
    "$ports_file" \
    "$artifact_root/tna_counter" \
    test.DirectCounterTest \
    'pkt_size=128'

echo "Open P4 Studio container self-test passed."
