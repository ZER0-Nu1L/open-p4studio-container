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
2. The current GHCR package is intentionally publicly pullable as an
   operational policy; this is not a legal determination.
3. A human must review redistribution rights for the exact pinned commit
   before publishing or mirroring it.
4. Only a repository/package administrator may change GHCR visibility.
5. CI never changes package visibility automatically.
6. A release tag must contain `Publication-Review: approved-public`. This
   records completion of the repository's publication gate; it is not legal
   advice or a transfer of upstream rights.

Release verification deliberately pulls the published digest without GHCR
credentials. Failure of that step means the package is not anonymously
available as documented and blocks Release creation.

The public image is limited to the Tofino 1 software model. Private Intel RDC
files, board support packages, hardware SerDes enablement, and other private
hardware materials are forbidden. CI requires pristine pinned upstream source
trees and rejects known RDC-only paths before building.
