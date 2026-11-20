# Matee CI - macOS - Tart

Use `matee.pkr.hcl` to build the macOS runner image with Packer and Tart.

## Prerequisites

- An Apple Silicon Mac with [Tart](https://github.com/cirruslabs/tart) installed
- [Packer](https://www.packer.io/) installed
- The `.xip` for your chosen Xcode version in `~/Downloads/` (e.g., `Xcode_26.2.xip`)

## Configuration

- `xcode_version` defaults to `26.2`.
- `java_version` defaults to `21`.

## VM Configuration

- **Base Image**: `ghcr.io/cirruslabs/macos-tahoe-base:latest`
- **CPU**: 4 cores
- **Memory**: 12 GB
- **Disk**: 120 GB
- **SSH Credentials**: admin/admin

## Installed Tools

- Xcode (customizable version)
- iOS and tvOS simulator runtimes
- OpenJDK (customizable version)
- Android SDK 37.1, build-tools 37.0.0, and platform-tools 37.0.1
- GitHub Actions Runner 2.338.2 for macOS ARM64 at `~/actions-runner`
- Fastlane
- SwiftLint
- Carthage
- Maestro
- Mint

## Usage

Run these commands from `mac/tart`.

```bash
packer init matee.pkr.hcl
packer build matee.pkr.hcl
```

### Build with custom Xcode/Java versions

```bash
packer build -var="xcode_version=26.1" -var="java_version=17" matee.pkr.hcl
```

## Output

Packer names the VM image `tarteletRunner-java-<java_version>-xcode-<xcode_version>`.
See the [macOS GitHub runner setup](../github/README.md) for registration and
labels.
