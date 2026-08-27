#!/usr/bin/env python3
"""Render the immutable image lock included with a GitHub Release."""

# Copyright 2026 Open P4 Studio Container contributors
# SPDX-License-Identifier: Apache-2.0

import argparse
import json
import re
from pathlib import Path


DIGEST_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
RELEASE_RE = re.compile(r"^sde-9\.13\.4-tofino1-r[1-9][0-9]*$")


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--image", required=True)
    parser.add_argument("--digest", required=True)
    parser.add_argument("--release", required=True)
    parser.add_argument("--versions", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    return parser.parse_args()


def load_versions(path):
    values = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#"):
            continue
        key, separator, value = line.partition("=")
        if not separator or not key or not value:
            raise SystemExit("invalid versions file line: {}".format(line))
        values[key] = value

    required = {
        "IMAGE_PLATFORM",
        "IMAGE_PROFILE",
        "OPEN_P4STUDIO_COMMIT",
        "P4C_COMMIT",
        "SDE_VERSION",
    }
    missing = sorted(required - values.keys())
    if missing:
        raise SystemExit("missing version fields: {}".format(", ".join(missing)))
    return values


def main():
    args = parse_args()
    if not DIGEST_RE.fullmatch(args.digest):
        raise SystemExit("invalid OCI digest")
    if not RELEASE_RE.fullmatch(args.release):
        raise SystemExit("invalid release tag")

    versions = load_versions(args.versions)
    manifest = {
        "image": "{}@{}".format(args.image, args.digest),
        "release": args.release,
        "platform": versions["IMAGE_PLATFORM"],
        "profile": versions["IMAGE_PROFILE"],
        "sde_version": versions["SDE_VERSION"],
        "open_p4studio_commit": versions["OPEN_P4STUDIO_COMMIT"],
        "p4c_commit": versions["P4C_COMMIT"],
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
