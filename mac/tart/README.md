# Matee CI - macOS - Tart

This directory contains Packer configuration for building macOS Tart VM images for CI/CD runners.

## Structure

- `matee.pkr.hcl` - Packer template for building macOS VM with Xcode, Java, Android SDK, and development tools
- `install-shared-toolchain.sh` - Pinned Android SDK, Gradle, Kotlin/Native, and Maestro provisioning

## Prerequisites

- [Tart](https://github.com/cirruslabs/tart) installed
- [Packer](https://www.packer.io/) installed
- Xcode `.xip` file downloaded to `~/Downloads/` (e.g., `Xcode_26.2.xip`)

## Configuration

The template supports the following variables:

- `xcode_version` - Xcode version to install (default: `26.2`)
- `java_version` - OpenJDK version to install (default: `21`)

## VM Configuration

- **Base Image**: `ghcr.io/cirruslabs/macos-tahoe-base:latest`
- **CPU**: 4 cores
- **Memory**: 12 GB
- **Disk**: 120 GB
- **SSH Credentials**: admin/admin

## Installed Tools

- Xcode (customizable version)
- OpenJDK (customizable version)
- Gradle 9.7.1 and Kotlin/Native 2.4.10
- Android platforms 37.1, 37.0, 36.1, 36, and 34
- Android build-tools 37.0.0, 36.1.0, 36.0.0, 35.0.0, and 34.0.0
- Android command-line tools 22.0 (build 15859902) and platform-tools 37.0.1
- GitHub Actions Runner for macOS ARM64, preinstalled at `~/actions-runner`
- Fastlane
- SwiftLint
- Carthage
- Maestro 2.10.0
- Mint

## Usage

### Build with default values

```bash
packer build matee.pkr.hcl
```

### Build with custom Xcode/Java versions

```bash
packer build -var="xcode_version=26.1" -var="java_version=17" matee.pkr.hcl
```

## Output

The resulting VM image will be named: `tarteletRunner-java-<java_version>-xcode-<xcode_version>`
