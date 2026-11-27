# macOS Tart runner image

Use an Apple silicon Mac with Tart and Packer. Run these commands from `mac/tart`.

## Build locally

Use `xcodes` to download the archives for the default Xcode versions.

```sh
./scripts/download-xcode-archives.sh 27.2 26.6
packer init matee.pkr.hcl
packer build matee.pkr.hcl
```

If verification fails in the terminal, download each archive from Apple
and save it as `~/Downloads/Xcode_<version>.xip`.
[Apple Developer Downloads](https://developer.apple.com/download/all/)

| Packer variable | Default |
| --- | --- |
| `xcode_version` | `27.2` |
| `additional_xcode_versions` | `["26.6"]` |
| `java_version` | `21` |
| `disk_size_gb` | `200` |
| `name_suffix` | `""` |

This build sets Xcode 26.6 as the default and keeps Xcode 27.2 available.

```sh
packer build -var='xcode_version=26.6' \
  -var='additional_xcode_versions=["27.2"]' matee.pkr.hcl
```

Set `additional_xcode_versions=[]` to install only the primary version.
Use a lowercase Pokémon name for `name_suffix`. For example,
`name_suffix=beautifly` sets the VM name to `matee-beautifly`.

## Image contents

- macOS Tahoe with 4 CPU cores and 12 GB of memory
- SSH user and password `admin`
- iOS and tvOS simulator runtimes for each installed Xcode version
- OpenJDK, Android SDK Platform 37.1, Build Tools 37.0.0, and Platform Tools 37.0.1
- Fastlane, SwiftLint, Carthage, Maestro, and Mint
- Latest stable GitHub Actions runner for macOS ARM64 in `~/actions-runner`

## Publish to Docker Hub

Install the Docker CLI, Python 3, and `xcodes` on the build Mac. Sign in
with a Docker Hub account that can push to `mateedevs/beautifly` and edit
its description.

```sh
./beautifly
```

Beautifly derives the tag from the build configuration and scripts. If the
tag exists, it skips the build and push. Use a new tag to rebuild with
updated upstream tools when the build configuration and scripts are the same.

- `./beautifly --yes` approves all steps.
- `./beautifly --set NAME=VALUE` overrides a Packer setting.
- `./beautifly --namespace NAME` selects a Docker Hub namespace.
- `./beautifly --publish-only TAG` retries the push with the original build settings.

## Set up a CI host

Clone the public image with the runner name for the CI host. Use
`matee-swablu` or `matee-altaria`.

```sh
tart clone registry-1.docker.io/mateedevs/beautifly:TAG matee-swablu
```


In Tartelet, open **Settings → Virtual Machine** and select the local VM.
Start the virtual machines from Tartelet to register the runners.

[Runner registration and labels](../github/README.md)

## Select Xcode in GitHub Actions

Set `DEVELOPER_DIR` to use Xcode 26.6 in later steps of the job.

```yaml
- name: Use Xcode 26.6
  run: |
    xcode_path=$(/usr/local/bin/xcodes installed 26.6)
    test -d "$xcode_path/Contents/Developer"
    echo "DEVELOPER_DIR=$xcode_path/Contents/Developer" >> "$GITHUB_ENV"
```
