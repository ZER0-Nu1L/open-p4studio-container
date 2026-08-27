# Licensing and publication gate

The Dockerfile, CI glue, documentation, and neutral self-test authored in this
repository are licensed under Apache-2.0.

The image also incorporates the pinned `p4lang/open-p4studio` checkout. Every
upstream component remains under its own license. The build preserves the
upstream `LICENSE`, `LICENSES/`, `ThirdPartyNotice.txt`, source notices, and the
Tofino model README. CI records their hashes and generates an SPDX SBOM.

Automated inventory is not a legal opinion. In particular, the repository
README describes the model binary as Intel-licensed even though much of the
surrounding source is Apache-2.0. Therefore:

1. The source repository is public.
2. The current GHCR package is publicly pullable; this is an operational fact,
   not a legal determination.
3. A human must review redistribution rights for the exact pinned commit
   before publishing, mirroring, or relying on anonymous pulls.
4. Only a repository/package administrator may change GHCR visibility.
5. CI never changes package visibility automatically.
