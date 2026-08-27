# Troubleshooting

## The image build runs out of disk

Use an otherwise clean amd64 Linux builder. GitHub Actions removes unrelated
Android, .NET, GHC, and CodeQL installations before building. Do not add the
SDE build directory or package caches back into the final image.

## `veth_setup.sh` or huge-page setup fails

The self-test requires a privileged container on a Linux host. Rootless Docker,
Docker Desktop VMs with restricted networking, and non-Linux hosts are not
supported by the model smoke test.

## `bf_switchd` never becomes ready

Inspect `switchd.log`, `model.log`, and the model runtime directory in the
mounted artifact directory. The wrapper waits up to 180 seconds and fails
early if either process exits.

## A custom program compiles but the launch scripts cannot find it

Compile with `$SDE/p4studio`, set `CMAKE_INSTALL_PREFIX=$SDE_INSTALL`, and run
the `install` target. The standard launch scripts require the generated target
configuration under `$SDE_INSTALL/share/p4/targets/tofino/`.
