#!/bin/bash
set -e
source "$HOME/.zprofile"
set -uo pipefail

# Butterfree build tag: build-jdk21-gradle9.7.1-kotlin2.4.10-sdk37.1-647f9c8f10f3
# Butterfree emulator tag: emulator-jdk21-sdk36-api34-maestro2.10.0-011cbe0196fb
maestro_version=2.10.0
android_cmdline_build=15859902
android_platform_tools_version=37.0.1

sdk_dir="$HOME/Android/sdk"
tools_dir="$HOME/.local/share/matee-ci"
staging_dir="$(mktemp -d)"
trap 'rm -rf "$staging_dir"' EXIT

download_verified() {
    local url="$1" archive="$2" checksum="$3"
    curl --fail --location --silent --show-error --retry 2 --connect-timeout 15 \
        --output "$archive" "$url"
    printf '%s  %s\n' "$checksum" "$archive" | shasum -a 256 -c -
}

google_repository=https://dl.google.com/android/repository
cmdline_archive="commandlinetools-mac_arm64-${android_cmdline_build}_latest.zip"
download_verified "$google_repository/$cmdline_archive" "$staging_dir/cmdline.zip" \
    835b62a26162b229b441d1f6d4680383815a270809eb33522c0d480fa5002c4e
download_verified "$google_repository/platform-tools_r$android_platform_tools_version-darwin.zip" \
    "$staging_dir/platform-tools.zip" ee39ad5967e95c2a07f04dbcbde96b1a0c916ba376096db5d2f498b7727a5d1d

mkdir -p "$sdk_dir/cmdline-tools" "$tools_dir"
unzip -q "$staging_dir/cmdline.zip" -d "$staging_dir"
mv "$staging_dir/cmdline-tools" "$sdk_dir/cmdline-tools/latest"
unzip -q "$staging_dir/platform-tools.zip" -d "$sdk_dir"

android="$sdk_dir/cmdline-tools/latest/bin/android"
"$android" --no-metrics --sdk="$sdk_dir" sdk install \
    platforms/android-37.1 platforms/android-37.0 platforms/android-36.1 platforms/android-36 platforms/android-34 \
    build-tools/37.0.0 build-tools/36.1.0 build-tools/36.0.0 build-tools/35.0.0 build-tools/34.0.0

download_verified "https://github.com/mobile-dev-inc/Maestro/releases/download/cli-$maestro_version/maestro.zip" \
    "$staging_dir/maestro.zip" 29b675e10cc12080e445e9bfb2e2b4e4dfb9c0f2e30d5884120d258b5e1cd991
unzip -q "$staging_dir/maestro.zip" -d "$tools_dir"

cat >>"$HOME/.zprofile" <<EOF
export ANDROID_HOME="\$HOME/Android/sdk"
export PATH="\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/build-tools/37.0.0:\$PATH"
export PATH="\$HOME/.local/share/matee-ci/maestro/bin:\$PATH"
EOF
