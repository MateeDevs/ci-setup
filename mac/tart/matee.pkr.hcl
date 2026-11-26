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
  default = "27.2"
}

variable "additional_xcode_versions" {
  type    = list(string)
  default = ["26.6"]
}

variable "disk_size_gb" {
  type    = number
  default = 200
}

variable "java_version" {
  type    = string
  default = "21"
}

variable "name_suffix" {
  type    = string
  default = ""
}

locals {
  xcode_versions = concat([var.xcode_version], var.additional_xcode_versions)
  vm_name_suffix = var.name_suffix == "" ? "" : "-${var.name_suffix}"
}

source "tart-cli" "tart" {
  vm_base_name = "ghcr.io/cirruslabs/macos-tahoe-base:latest"
  vm_name      = "matee${local.vm_name_suffix}"

  cpu_count    = 4
  memory_gb    = 12
  disk_size_gb = var.disk_size_gb
  ssh_password = "admin"
  ssh_username = "admin"
  ssh_timeout  = "120s"
  headless     = true
}

build {
  sources = ["source.tart-cli.tart"]

  # Check the required archives on the build Mac before uploading them.
  provisioner "shell-local" {
    script = "${path.root}/scripts/check-xcode-archives.sh"
    environment_vars = [
      "XCODE_VERSIONS=${join(" ", local.xcode_versions)}",
    ]
  }

  provisioner "file" {
    sources     = [for version in local.xcode_versions : pathexpand("~/Downloads/Xcode_${version}.xip")]
    destination = "/Users/admin/Downloads/"
    # Let the local check report missing archives first.
    generated = true
  }

  # Install Xcode and set the default version.
  provisioner "shell" {
    script = "${path.root}/scripts/install-xcode.sh"
    environment_vars = [
      "XCODE_VERSIONS=${join(" ", local.xcode_versions)}",
      "PRIMARY_XCODE_VERSION=${var.xcode_version}",
    ]
  }

  # Install Java.
  provisioner "shell" {
    script = "${path.root}/scripts/install-java.sh"
    environment_vars = [
      "JAVA_VERSION=${var.java_version}",
    ]
  }

  # Install the Android SDK.
  provisioner "shell" {
    script = "${path.root}/scripts/install-android-sdk.sh"
  }

  # Install the GitHub Actions runner.
  provisioner "shell" {
    script = "${path.root}/scripts/install-github-runner.sh"
  }

  # Install build tools and check disk space.
  provisioner "shell" {
    script = "${path.root}/scripts/install-development-tools.sh"
  }
}
