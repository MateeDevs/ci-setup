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

locals {
  github_runner_version = "2.338.2"
  github_runner_sha256  = "25a065af409ffa317ab4d5a3b614dd15fc9c40f2172bc1b35a1b1258e919a388"
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
      "xcodebuild -downloadPlatform tvOS",
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

  # 4. Android SDK a Maestro
  provisioner "shell" {
    script = "${path.root}/install-android-and-maestro.sh"
  }

  # 5. GitHub Actions Runner
  provisioner "shell" {
    inline = [<<-SHELL
      set -eu

      runner_version="${local.github_runner_version}"
      archive_name="actions-runner-osx-arm64-$runner_version.tar.gz"
      staging_dir="$(mktemp -d)"
      trap 'rm -rf "$staging_dir"' EXIT
      archive="$staging_dir/$archive_name"

      curl --fail --location --silent --show-error --retry 2 \
        --output "$archive" "https://github.com/actions/runner/releases/download/v$runner_version/$archive_name"
      printf '%s  %s\n' '${local.github_runner_sha256}' "$archive" | shasum -a 256 -c -

      mkdir "$staging_dir/actions-runner"
      tar -xzf "$archive" -C "$staging_dir/actions-runner"
      test "$("$staging_dir/actions-runner/bin/Runner.Listener" --version)" = "$runner_version"
      test ! -e "$HOME/actions-runner"
      mv "$staging_dir/actions-runner" "$HOME/actions-runner"
    SHELL
    ]
  }

  # 6. Fastlane, SwiftLint, doplňky a kontrola místa
  provisioner "shell" {
    inline = [
      "source ~/.zprofile",
      "echo '--- Installing Development Tools (Fastlane, SwiftLint) ---'",
      "brew install fastlane swiftlint",
      "brew install carthage unzip zip ca-certificates mint",
      
      "echo 'Final check of disk space:'",
      "df -h /",
      "export FREE_MB=$(df -m / | awk 'NR==2 {print $4}')",
      "[[ $FREE_MB -gt 15000 ]] && echo 'Disk space OK' || (echo 'Not enough space!' && exit 1)"
    ]
  }
}
