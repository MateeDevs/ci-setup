#!/bin/bash -e

source ~/.zprofile
bash /tmp/matee-download-progress.sh 'Install Android command-line tools' \
  brew install --cask android-commandlinetools

# Use the runner user's SDK directory and add the SDK tools to PATH.
mkdir -p ~/Android/sdk
echo 'export ANDROID_HOME="$HOME/Android/sdk"' >> ~/.zprofile
echo 'export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/37.0.0:$PATH"' >> ~/.zprofile
source ~/.zprofile

# Accept the SDK licenses and install the platform and build tools.
yes | sdkmanager --sdk_root="$ANDROID_HOME" --licenses
bash /tmp/matee-download-progress.sh 'Install Android SDK packages' \
  sdkmanager --sdk_root="$ANDROID_HOME" --install \
  "platforms;android-37.1" "build-tools;37.0.0"

# Use Google's archive to install the exact Platform-Tools version.
platform_tools_version=37.0.1
platform_tools_sha256=ee39ad5967e95c2a07f04dbcbde96b1a0c916ba376096db5d2f498b7727a5d1d
staging_dir="$(mktemp -d)"
trap 'rm -rf "$staging_dir"' EXIT
archive="$staging_dir/platform-tools.zip"

bash /tmp/matee-download-progress.sh "Download Android Platform-Tools $platform_tools_version" \
  curl --fail --location --retry 3 --output "$archive" \
  "https://dl.google.com/android/repository/platform-tools_r${platform_tools_version}-darwin.zip"
printf '%s  %s\n' "$platform_tools_sha256" "$archive" | shasum -a 256 -c -
unzip -oq "$archive" -d "$ANDROID_HOME"
