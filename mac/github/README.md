# GitHub Actions runners on macOS

The [Tart image](../tart/README.md) includes the ARM64 runner at
`~/actions-runner`. Register it when you deploy the VM. For a standalone Mac,
follow the [GitHub runner setup guide](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/add-runners).

## Labels

Choose labels from the [runner overview](../../runner/README.md). Add them
during registration or under **Settings → Actions → Runners** in GitHub.

## Standalone runner service

After registration, run `./svc.sh` from the runner directory. See the
[GitHub service guide](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/configure-the-application?platform=mac).
