# Releasing an image

Releases are immutable and use tags shaped like:

```text
sde-9.13.4-tofino1-r1
```

## Procedure

1. Update the open-p4studio gitlink and `ci/image/versions.env` together.
2. Run the PR workflow and review both model self-tests and license inventory.
3. Merge to `main` and wait for the main validation workflow.
4. Create the next unused release tag on the validated main commit.
5. Push the tag. The release workflow rebuilds, tests, pushes, pulls the image
   by digest on a fresh runner, and tests again.
6. Confirm the GitHub Release contains `image-lock.json`, SPDX SBOM, source
   inventory, and both sets of test logs.

Never move or overwrite an existing release tag. A changed Dockerfile, base
image, SDE profile, open-p4studio commit, or p4c commit requires a new `rN` and
a new digest.

Consumers should copy the `image` value from `image-lock.json`. They should not
derive a reference from the release tag and should not consume a floating tag.
