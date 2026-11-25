# macOS Tart runner image

## Build

1. Install Tart and Packer on an Apple silicon Mac. [Tart](https://github.com/cirruslabs/tart) · [Packer](https://www.packer.io/)
2. Open a terminal in `mac/tart`.
3. Run these commands.

```sh
packer init matee.pkr.hcl
packer build matee.pkr.hcl
```

Packer looks for each Xcode archive in `~/Downloads/Xcode_<version>.xip`.
If an archive is missing, Packer uses `xcodes` to download it on the build Mac.
For downloads, install `xcodes` and set up Apple Developer sign-in for the
user who runs Packer. [xcodes](https://github.com/XcodesOrg/xcodes)

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
