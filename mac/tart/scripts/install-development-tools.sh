#!/bin/bash -e

source ~/.zprofile
echo 'Installing build tools'
brew install fastlane swiftlint
brew install carthage unzip zip ca-certificates mint
brew tap mobile-dev-inc/tap
brew install mobile-dev-inc/tap/maestro

# Check free space after all tools are installed.
echo 'Checking free disk space'
df -h /
export FREE_MB=$(df -m / | awk 'NR==2 {print $4}')
[[ $FREE_MB -gt 15000 ]] && echo 'Disk space OK' || (echo 'The image needs more than 15000 MB of free disk space.' >&2 && exit 1)
