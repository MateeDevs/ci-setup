packer {
  required_plugins {
    tart = {
      version = ">= 1.12.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

variable "xcode_version" {
  type    = string
  default = "26.2"
}

variable "java_version" {
  type    = string
  default = "21"
}

source "tart-cli" "tart" {
  vm_base_name = "ghcr.io/cirruslabs/macos-tahoe-base:latest"
  vm_name      = "tarteletRunner-java-${var.java_version}-xcode-${var.xcode_version}"
  
  cpu_count    = 4
  memory_gb    = 12
  disk_size_gb = 120
  ssh_password = "admin"
  ssh_username = "admin"
  ssh_timeout  = "120s"
  headless     = true
}

build {
  sources = ["source.tart-cli.tart"]

  # 1. Nahrání Xcode xip
  provisioner "file" {
    source      = pathexpand("~/Downloads/Xcode_${var.xcode_version}.xip")
    destination = "/Users/admin/Downloads/Xcode_${var.xcode_version}.xip"
  }

  # 2. Instalace xcodes a Xcode
  provisioner "shell" {
    inline = [
      "echo '--- Installing xcodes binary ---'",
      "curl -L -o xcodes.zip https://github.com/RobotsAndPencils/xcodes/releases/latest/download/xcodes.zip",
      "unzip xcodes.zip && sudo mv xcodes /usr/local/bin/xcodes && rm xcodes.zip",
      
      "echo '--- Setting up Environment ---'",
      "echo 'export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH' >> ~/.zprofile",
      "source ~/.zprofile",

      "echo '--- Installing Xcode from local file ---'",
      "sudo xcodes install ${var.xcode_version} --path /Users/admin/Downloads/Xcode_${var.xcode_version}.xip --select --experimental-unxip --empty-trash",

      "echo '--- Post-install setup ---'",
      "xcodebuild -downloadPlatform ios",
      "xcodebuild -runFirstLaunch",
      "sudo /usr/sbin/softwareupdate --install-rosetta --agree-to-license",
      "defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES",
      "defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES",
      "defaults write com.apple.dt.Xcode IDEPackageEnablePrebuilts YES"
    ]
  }

  # 3. Java 21
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install openjdk@${var.java_version}",
      "echo 'export PATH=\"/opt/homebrew/opt/openjdk@${var.java_version}/bin:$PATH\"' >> ~/.zprofile",
      "echo 'export JAVA_HOME=\"/opt/homebrew/opt/openjdk@${var.java_version}\"' >> ~/.zprofile",
      "sudo ln -sfn /opt/homebrew/opt/openjdk@${var.java_version}/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-${var.java_version}.jdk"
    ]
  }

  # 4. Android SDK 34
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "brew install --cask android-commandlinetools",
      "mkdir -p ~/Android/sdk",
      "echo 'export ANDROID_HOME=\"$HOME/Android/sdk\"' >> ~/.zprofile",
      "echo 'export PATH=\"$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/34.0.0:$PATH\"' >> ~/.zprofile",
      "source ~/.zprofile",
      "yes | sdkmanager --sdk_root=$ANDROID_HOME --install \"platform-tools\" \"platforms;android-34\" \"build-tools;34.0.0\""
    ]
  }

  # 5. Fastlane, SwiftLint, doplňky a kontrola místa
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "echo '--- Installing Development Tools (Fastlane, SwiftLint) ---'",
      "brew install fastlane swiftlint",
      "brew install carthage unzip zip ca-certificates mint",
      "brew tap mobile-dev-inc/tap",
      "brew install mobile-dev-inc/tap/maestro",
      
      "echo 'Final check of disk space:'",
      "df -h /",
      "export FREE_MB=$(df -m / | awk 'NR==2 {print $4}')",
      "[[ $FREE_MB -gt 15000 ]] && echo 'Disk space OK' || (echo 'Not enough space!' && exit 1)"
    ]
  }
}