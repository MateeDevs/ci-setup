#!/bin/bash -e

source ~/.zprofile
java_prefix="/opt/homebrew/opt/openjdk@$JAVA_VERSION"

brew install "openjdk@$JAVA_VERSION"

# Set Java for login shells and register the JDK with macOS.
printf 'export PATH="%s/bin:$PATH"\n' "$java_prefix" >> ~/.zprofile
printf 'export JAVA_HOME="%s"\n' "$java_prefix" >> ~/.zprofile
sudo ln -sfn "$java_prefix/libexec/openjdk.jdk" "/Library/Java/JavaVirtualMachines/openjdk-$JAVA_VERSION.jdk"
