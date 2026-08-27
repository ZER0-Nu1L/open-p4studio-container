#!/usr/bin/env bash
# Copyright 2026 Open P4 Studio Container contributors
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

if [[ $# -lt 5 ]]; then
    echo "Usage: $0 PROGRAM TEST_DIR PORTS_FILE ARTIFACT_DIR TEST_SELECTOR [TEST_PARAMS]" >&2
    exit 2
fi

program_name=$1
test_dir=$2
ports_file=$3
artifact_dir=$4
test_selector=$5
test_params=${6:-}

: "${SDE:?SDE must be set}"
: "${SDE_INSTALL:?SDE_INSTALL must be set}"

mkdir -p "$artifact_dir/model-runtime"
model_pid=
switchd_pid=

cleanup() {
    local pid
    for pid in "$switchd_pid" "$model_pid"; do
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            kill -TERM -- "-$pid" 2>/dev/null || true
        fi
    done
    sleep 2
    for pid in "$switchd_pid" "$model_pid"; do
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            kill -KILL -- "-$pid" 2>/dev/null || true
        fi
        if [[ -n "$pid" ]]; then
            wait "$pid" 2>/dev/null || true
        fi
    done
}
trap cleanup EXIT INT TERM

setsid "$SDE/run_tofino_model.sh" \
    -p "$program_name" \
    -f "$ports_file" \
    --arch tofino \
    --log-dir "$artifact_dir/model-runtime" \
    >"$artifact_dir/model.log" 2>&1 &
model_pid=$!

sleep 2
kill -0 "$model_pid"

setsid "$SDE/run_switchd.sh" \
    -p "$program_name" \
    --arch tofino \
    --server-listen-local-only \
    -C \
    >"$artifact_dir/switchd.log" 2>&1 &
switchd_pid=$!

deadline=$((SECONDS + ${SWITCHD_READY_TIMEOUT:-180}))
until (echo >/dev/tcp/127.0.0.1/7777) 2>/dev/null; do
    kill -0 "$model_pid" 2>/dev/null || {
        echo "Tofino model exited before switchd became ready" >&2
        exit 1
    }
    kill -0 "$switchd_pid" 2>/dev/null || {
        echo "bf_switchd exited before its status server became ready" >&2
        exit 1
    }
    if ((SECONDS >= deadline)); then
        echo "Timed out waiting for bf_switchd status port" >&2
        exit 1
    fi
    sleep 2
done

sleep 5

test_command=(
    "$SDE/run_p4_tests.sh"
    -p "$program_name"
    --arch tofino
    --no-veth
    -t "$test_dir"
    -f "$ports_file"
    -s "$test_selector"
)
if [[ -n "$test_params" ]]; then
    test_command+=(--test-params "$test_params")
fi

"${test_command[@]}" 2>&1 | tee "$artifact_dir/ptf.log"
