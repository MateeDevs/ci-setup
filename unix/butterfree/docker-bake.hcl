variable "DOCKERHUB_NAMESPACE" {
  default = "mateedevs"
}

variable "BUTTERFREE_IMAGE_TAG" {
  default = "build-jdk21-gradle9.7.1-kotlin2.4.10-sdk37.1-647f9c8f10f3"
}

variable "EMULATOR_IMAGE_TAG" {
  default = "emulator-jdk21-sdk37.1-api34-maestro2.9.0-80b2146f404f"
}

variable "UBUNTU_VERSION" {
  default = "22.04"
}

variable "JAVA_VERSION" {
  default = "21"
}

variable "GRADLE_VERSION" {
  default = "9.7.1"
}

variable "GRADLE_SHA256" {
  default = "acd53f1edaf02f1a8ff99879f8a34b302661a057d9b063ae9e35b552f804d20a"
}

variable "KOTLIN_VERSION" {
  default = "2.4.10"
}

variable "KOTLIN_NATIVE_SHA256" {
  default = "c9e356e8518144f275f1514cfe38b07db949f93e47e054832b8974fff1fd33e0"
}

variable "ANDROID_CMDLINE_TOOLS_VERSION" {
  default = "15859902"
}

variable "ANDROID_CMDLINE_TOOLS_SHA256" {
  default = "4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583"
}

variable "ANDROID_BUILD_TOOLS_VERSIONS" {
  default = "37.0.0,36.1.0,36.0.0"
}

variable "ANDROID_PLATFORM_VERSIONS" {
  default = "37.1,37.0,36.1"
}

variable "ANDROID_PLATFORM_TOOLS_VERSION" {
  default = "37.0.1"
}

variable "ANDROID_EMULATOR_VERSION" {
  default = "37.1.11"
}

variable "EMULATOR_ARCH" {
  default = "x86_64"
}

variable "EMULATOR_TARGET" {
  default = "google_apis_playstore"
}

variable "EMULATOR_API_LEVEL" {
  default = "34"
}

variable "EMULATOR_NAME" {
  default = "Pixel_7_Pro"
}

variable "EMULATOR_DEVICE" {
  default = "pixel_7_pro"
}

variable "MAESTRO_VERSION" {
  default = "2.9.0"
}

variable "MAESTRO_SHA256" {
  default = "855bb2ce1399d82f4f4a73d84a4d945f70b0d43eb86127e027af82809f63f0bd"
}

group "default" {
  targets = ["butterfree", "emulator"]
}

target "common" {
  context    = "."
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64"]
  args = {
    UBUNTU_VERSION                   = UBUNTU_VERSION
    JAVA_VERSION                     = JAVA_VERSION
    GRADLE_VERSION                   = GRADLE_VERSION
    GRADLE_SHA256                    = GRADLE_SHA256
    KOTLIN_VERSION                   = KOTLIN_VERSION
    KOTLIN_NATIVE_SHA256             = KOTLIN_NATIVE_SHA256
    ANDROID_CMDLINE_TOOLS_VERSION    = ANDROID_CMDLINE_TOOLS_VERSION
    ANDROID_CMDLINE_TOOLS_SHA256     = ANDROID_CMDLINE_TOOLS_SHA256
    ANDROID_BUILD_TOOLS_VERSIONS     = ANDROID_BUILD_TOOLS_VERSIONS
    ANDROID_PLATFORM_VERSIONS        = ANDROID_PLATFORM_VERSIONS
    ANDROID_PLATFORM_TOOLS_VERSION   = ANDROID_PLATFORM_TOOLS_VERSION
    ANDROID_EMULATOR_VERSION         = ANDROID_EMULATOR_VERSION
    EMULATOR_ARCH                    = EMULATOR_ARCH
    EMULATOR_TARGET                  = EMULATOR_TARGET
    EMULATOR_API_LEVEL               = EMULATOR_API_LEVEL
    EMULATOR_NAME                    = EMULATOR_NAME
    EMULATOR_DEVICE                  = EMULATOR_DEVICE
    MAESTRO_VERSION                  = MAESTRO_VERSION
    MAESTRO_SHA256                   = MAESTRO_SHA256
  }
}

target "butterfree" {
  inherits = ["common"]
  target   = "butterfree"
  args = {
    IMAGE_VERSION = BUTTERFREE_IMAGE_TAG
  }
  tags = [
    "${DOCKERHUB_NAMESPACE}/butterfree:${BUTTERFREE_IMAGE_TAG}",
  ]
}

target "emulator" {
  inherits = ["common"]
  target   = "emulator"
  args = {
    IMAGE_VERSION = EMULATOR_IMAGE_TAG
  }
  tags = [
    "${DOCKERHUB_NAMESPACE}/butterfree:${EMULATOR_IMAGE_TAG}",
  ]
}
