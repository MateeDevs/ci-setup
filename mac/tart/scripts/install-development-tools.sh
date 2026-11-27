#!/bin/bash -e

source ~/.zprofile
bash /tmp/matee-download-progress.sh 'Update Homebrew' brew update

bash /tmp/matee-download-progress.sh 'Install Fastlane and SwiftLint' brew install fastlane swiftlint
bash /tmp/matee-download-progress.sh 'Install additional build tools' brew install carthage unzip zip ca-certificates mint
bash /tmp/matee-download-progress.sh 'Add the Maestro Homebrew tap' brew tap mobile-dev-inc/tap
bash /tmp/matee-download-progress.sh 'Install Maestro' brew install mobile-dev-inc/tap/maestro
rm -f /tmp/matee-download-progress.sh

echo 'Installed build tool versions'
brew list --versions fastlane swiftlint carthage unzip zip ca-certificates mint mobile-dev-inc/tap/maestro

# Check free space after all tools are installed.
echo 'Checking free disk space'
df -h /
export FREE_MB=$(df -m / | awk 'NR==2 {print $4}')
[[ $FREE_MB -gt 15000 ]] && echo 'Disk space OK' || (echo 'The image needs more than 15000 MB of free disk space.' >&2 && exit 1)
