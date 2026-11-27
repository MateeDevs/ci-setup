#!/bin/bash

set -e

echo 'Installing xcodes'
bash /tmp/matee-download-progress.sh 'Download xcodes' \
  curl --fail --location -o xcodes.zip \
  https://github.com/XcodesOrg/xcodes/releases/latest/download/xcodes.zip
unzip xcodes.zip
sudo mv xcodes /usr/local/bin/xcodes
rm xcodes.zip

# Add Homebrew and xcodes to PATH for login shells.
echo 'export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH' >> ~/.zprofile
source ~/.zprofile

download_runtime() {
  local platform=$1
  local version=$2
  local attempt delay exit_code

  for attempt in 1 2 3; do
    if bash /tmp/matee-download-progress.sh \
      "Download the $platform simulator runtime for Xcode $version (attempt $attempt of 3)" \
      xcodebuild -downloadPlatform "$platform"; then
      return 0
    else
      exit_code=$?
    fi

    if [[ "$attempt" -eq 3 ]]; then
      echo "Cannot download the $platform simulator runtime after 3 attempts." >&2
      return "$exit_code"
    fi

    delay=$((attempt * 15))
    echo "Wait $delay seconds before the next $platform runtime download." >&2
    sleep "$delay"
  done
}

read -r -a versions <<< "$XCODE_VERSIONS"
# Select each version before downloading its simulator runtimes.
for version in "${versions[@]}"; do
  echo "Installing Xcode $version from the local archive"
  sudo /usr/local/bin/xcodes install "$version" --path "$HOME/Downloads/Xcode_$version.xip" --select --experimental-unxip --empty-trash
  download_runtime iOS "$version"
  download_runtime tvOS "$version"
  xcodebuild -runFirstLaunch
done

# Set the version that jobs use by default.
sudo /usr/local/bin/xcodes select "${PRIMARY_XCODE_VERSION}"
bash /tmp/matee-download-progress.sh 'Install Rosetta' \
  sudo /usr/sbin/softwareupdate --install-rosetta --agree-to-license

# Set Swift package options for CI builds.
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
defaults write com.apple.dt.Xcode IDEPackageEnablePrebuilts YES
