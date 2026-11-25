#!/bin/bash

set -e

echo 'Installing xcodes'
curl --fail --location -o xcodes.zip https://github.com/XcodesOrg/xcodes/releases/latest/download/xcodes.zip
unzip xcodes.zip
sudo mv xcodes /usr/local/bin/xcodes
rm xcodes.zip

# Add Homebrew and xcodes to PATH for login shells.
echo 'export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH' >> ~/.zprofile
source ~/.zprofile

read -r -a versions <<< "$XCODE_VERSIONS"
# Select each version before downloading its simulator runtimes.
for version in "${versions[@]}"; do
  echo "Installing Xcode $version from the local archive"
  sudo /usr/local/bin/xcodes install "$version" --path "$HOME/Downloads/Xcode_$version.xip" --select --experimental-unxip --empty-trash
  xcodebuild -downloadPlatform ios
  xcodebuild -downloadPlatform tvOS
  xcodebuild -runFirstLaunch
done

# Set the version that jobs use by default.
sudo /usr/local/bin/xcodes select "${PRIMARY_XCODE_VERSION}"
sudo /usr/sbin/softwareupdate --install-rosetta --agree-to-license

# Set Swift package options for CI builds.
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
defaults write com.apple.dt.Xcode IDEPackageEnablePrebuilts YES
