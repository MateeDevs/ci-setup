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

## Image

Packer names the image `tarteletRunner-java-<java_version>-xcode-<xcode_version>`.
Set `name_suffix` to append a hyphen and a suffix to the image name.

```sh
packer build -var='name_suffix=test' matee.pkr.hcl
```

The macOS Tahoe VM has 4 CPU cores and 12 GB of memory. The SSH user and
password are both `admin`.

The image includes iOS and tvOS simulator runtimes, OpenJDK, Android SDK 37.1,
Fastlane, SwiftLint, Carthage, Maestro, and Mint.

Packer downloads the latest stable GitHub Actions runner for macOS ARM64.
Packer checks the SHA-256 checksum, then installs the runner in `~/actions-runner`.
[Runner registration and labels](../github/README.md)

## Select Xcode in GitHub Actions

Jobs use the primary Xcode by default. To use Xcode 26.6, add this step before
the build step in the same job.

```yaml
- name: Use Xcode 26.6
  run: echo "DEVELOPER_DIR=$(/usr/local/bin/xcodes installed 26.6)/Contents/Developer" >> "$GITHUB_ENV"
```
