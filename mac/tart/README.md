# Matee CI - macOS - Tart

This directory contains Packer configuration for building macOS Tart VM images for CI/CD runners.

## Structure

- `matee.pkr.hcl` - Packer template for building macOS VM with Xcode, Java, Android SDK, and development tools

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
- Android SDK 34
- Fastlane
- SwiftLint
- Carthage
- Maestro
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
