# macOS Tart runner image

Install Tart and Packer on an Apple silicon Mac.
Run the commands in this guide from `mac/tart`.
[Tart](https://github.com/cirruslabs/tart) · [Packer](https://www.packer.io/)

## Get the Xcode archives

Save each required archive as `~/Downloads/Xcode_<version>.xip`.
Packer checks the files before upload. If a file is missing, Packer prints
a download command for the missing versions and stops.

Install `xcodes` on the build Mac. Run the download script in a terminal.
Give the script the Xcode versions from your build configuration.
The script skips files that already exist. [xcodes](https://github.com/XcodesOrg/xcodes)

To get the default versions, run this command.

```sh
./scripts/download-xcode-archives.sh 27.2 26.6
```

If Apple asks for a verification code, enter it in the terminal.
If you cannot enter the code, use a browser to download the XIP files.
Save each file in `~/Downloads` with the name shown above.
[Apple Developer Downloads](https://developer.apple.com/download/all/)

## Build the image

```sh
packer init matee.pkr.hcl
packer build matee.pkr.hcl
```

## Defaults

| Packer variable | Default |
| --- | --- |
| `xcode_version` | `27.2` |
| `additional_xcode_versions` | `["26.6"]` |
| `java_version` | `21` |
| `disk_size_gb` | `200` |
| `name_suffix` | `""` |

To change a value, use `-var`. To install only the primary Xcode, add
`-var='additional_xcode_versions=[]'` to the build command.

To make Xcode 26.6 the default and keep Xcode 27.2 available, download both
archives and run this command.

```sh
packer build -var='xcode_version=26.6' \
  -var='additional_xcode_versions=["27.2"]' matee.pkr.hcl
```

## Image

Packer names the image `matee` by default. When you set `name_suffix`, use a
lowercase Pokémon name. This example creates `matee-swablu`.

```sh
packer build -var='name_suffix=swablu' matee.pkr.hcl
```

The macOS Tahoe VM has 4 CPU cores and 12 GB of memory. The SSH user and
password are both `admin`.

Packer installs iOS and tvOS simulator runtimes for each Xcode version.
The image also includes OpenJDK, Android SDK Platform 37.1, Android Build
Tools 37.0.0, Android Platform Tools 37.0.1, Fastlane, SwiftLint, Carthage,
Maestro, and Mint.

Packer downloads the latest stable GitHub Actions runner for macOS ARM64.
Packer checks the archive's SHA-256 checksum and the runner version before
installing it in `~/actions-runner`.
[Runner registration and labels](../github/README.md)

## Select Xcode in GitHub Actions

Jobs use the version set by `xcode_version` by default. To use another
installed version, set `DEVELOPER_DIR` before running any Xcode commands.
This example uses Xcode 26.6 for later steps in the same job.

```yaml
- name: Use Xcode 26.6
  run: |
    xcode_path=$(/usr/local/bin/xcodes installed 26.6)
    test -d "$xcode_path/Contents/Developer"
    echo "DEVELOPER_DIR=$xcode_path/Contents/Developer" >> "$GITHUB_ENV"
```
