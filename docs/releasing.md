# Releasing an image

Releases are immutable and use tags shaped like:

```text
sde-9.13.4-tofino1-r1
```

## Procedure

1. Update the open-p4studio gitlink and `ci/image/versions.env` together.
2. Run the PR workflow and review both model self-tests, the source/license
   inventory, and the absence of private hardware material.
3. Merge through a pull request and wait for the exact `main` commit's
   validation workflow to succeed.
4. Re-fetch `main`, select the next unused `rN`, and create an annotated tag on
   that exact commit. The tag message must include the exact marker
   `Publication-Review: approved-public` on its own line.
5. Push only the new tag. The release workflow verifies that it is annotated,
   still points to current `origin/main`, matches the SDE/profile pinned in
   `versions.env`, and carries the publication marker.
6. The workflow rebuilds, tests, pushes, pulls the digest anonymously on a
   fresh runner, and runs both model self-tests again.
7. Confirm the GitHub Release contains `image-lock.json`, `checksums.sha256`,
   the SPDX SBOM, source inventory, and both sets of test logs.

For example, after replacing the placeholders with reviewed values:

```bash
git fetch origin main --tags
release_commit=$(git rev-parse origin/main)
release_tag=sde-9.13.4-tofino1-r3
git tag --annotate "$release_tag" "$release_commit" \
  --message "Release Open P4 Studio 9.13.4 Tofino 1 model container r3" \
  --message "Publication-Review: approved-public"
git push origin "refs/tags/$release_tag"
```

Never move or overwrite an existing release tag. A changed Dockerfile, base
image, SDE profile, open-p4studio commit, or p4c commit requires a new `rN` and
a new digest. If a tagged release fails, preserve that tag and fix the problem
under the next release number. Repository rules should prevent update or
deletion of matching release tags.

Consumers should first verify `image-lock.json` against `checksums.sha256`,
require `schema_version` 1, and check `source_repository`, `container_commit`,
`release`, and the pinned toolchain fields. They should then consume the exact
`image` value. They must not derive a reference from the release tag or consume
a floating tag.

The GHCR package is publicly pullable by explicit operational policy. The
policy, anonymous pull-back test, tag marker, SBOM, and inventory provide
auditable release evidence; none is a legal opinion about Intel-licensed
upstream binaries. Never add private RDC, BSP, or physical-hardware enablement
material to this repository or image.
