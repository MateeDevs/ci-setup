# macOS Tart runner image

## Build

1. Install Tart and Packer on an Apple silicon Mac. [Tart](https://github.com/cirruslabs/tart) · [Packer](https://www.packer.io/)
2. Open a terminal in `mac/tart`.
3. Run these commands.

```sh
packer init matee.pkr.hcl
packer build matee.pkr.hcl
```

Packer uses Xcode archives at `~/Downloads/Xcode_<version>.xip`.
If an archive is missing, Packer downloads it with `xcodes`.
To download archives, install `xcodes` on the build Mac.
Use an Apple Developer account to sign in. [xcodes](https://github.com/XcodesOrg/xcodes)

If Apple asks for a verification code, enter the code in the build terminal.
If the build has no terminal, download the archives before you start Packer.
Open a terminal in `mac/tart` on the build Mac. Run this command to download
the default Xcode versions.

```sh
./scripts/download-xcode-archives.sh 27.2 26.6
```

Complete Apple sign-in. Then start the Packer build.

## Defaults

| Packer variable | Default |
| --- | --- |
| `xcode_version` | `27.2` |
| `additional_xcode_versions` | `["26.6"]` |
| `java_version` | `21` |
| `disk_size_gb` | `200` |

Use `-var` to change a default. To install only the primary Xcode, add
`-var='additional_xcode_versions=[]'` to the build command.

## Image

The macOS Tahoe VM has 4 CPU cores and 12 GB of memory.
The SSH user and password are both `admin`.

The VM includes iOS and tvOS simulator runtimes, OpenJDK, Android SDK 37.1,
Fastlane, SwiftLint, Carthage, Maestro, and Mint.

Packer names the image `tarteletRunner-java-<java_version>-xcode-<xcode_version>`.
It downloads the latest stable GitHub Actions runner for macOS ARM64.
It checks the archive's SHA-256 checksum before installing the runner in
`~/actions-runner`. [Runner registration and labels](../github/README.md)

## Select Xcode in GitHub Actions

Jobs use the primary Xcode by default. To use Xcode 26.6, add this step before
the build step in the same job.

```yaml
- name: Use Xcode 26.6
  run: echo "DEVELOPER_DIR=$(/usr/local/bin/xcodes installed 26.6)/Contents/Developer" >> "$GITHUB_ENV"
```
