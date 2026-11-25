#!/bin/bash -e

source ~/.zprofile
brew install --cask android-commandlinetools

# Use the runner user's SDK directory and add the SDK tools to PATH.
mkdir -p ~/Android/sdk
echo 'export ANDROID_HOME="$HOME/Android/sdk"' >> ~/.zprofile
echo 'export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/37.0.0:$PATH"' >> ~/.zprofile
source ~/.zprofile

# Install the SDK packages used by CI.
android --no-metrics --sdk="$ANDROID_HOME" sdk install "platform-tools@37.0.1" "platforms/android-37.1" "build-tools/37.0.0"
