# GitHub Actions runners on macOS

## Tart runners

Set the GitHub App credentials in **Settings → GitHub** in Tartelet.
Tartelet registers the runner when it starts the VM.
[Tartelet configuration guide](https://github.com/framna-dk/tartelet/wiki/Configuring-Tartelet)

## Labels

Choose labels from the [runner overview](../../runner/README.md). Set them
in Tartelet for Tart runners. For standalone runners, set them during
registration or under **Settings → Actions → Runners** in GitHub.

## Standalone runner service

Follow the [GitHub runner setup guide](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/add-runners).
After registration, run `./svc.sh` from the runner directory. See the
[GitHub service guide](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/configure-the-application?platform=mac).
