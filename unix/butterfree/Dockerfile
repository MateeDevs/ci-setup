# syntax=docker/dockerfile:1.7

ARG UBUNTU_VERSION=22.04

FROM ubuntu:${UBUNTU_VERSION} AS android

ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH
ARG IMAGE_VERSION=development
ARG UBUNTU_VERSION=22.04
ARG JAVA_VERSION=21
ARG GRADLE_VERSION=9.7.1
ARG GRADLE_SHA256=acd53f1edaf02f1a8ff99879f8a34b302661a057d9b063ae9e35b552f804d20a
ARG KOTLIN_VERSION=2.4.10
ARG KOTLIN_NATIVE_SHA256=c9e356e8518144f275f1514cfe38b07db949f93e47e054832b8974fff1fd33e0
ARG ANDROID_CMDLINE_TOOLS_VERSION=15859902
ARG ANDROID_CMDLINE_TOOLS_SHA256=4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583
ARG ANDROID_BUILD_TOOLS_VERSIONS=37.0.0,36.1.0,36.0.0
ARG ANDROID_PLATFORM_VERSIONS=37.1,37.0,36.1
ARG ANDROID_PLATFORM_TOOLS_VERSION=37.0.1

LABEL org.opencontainers.image.title="butterfree" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.description="Java, Gradle, Kotlin/Native, and Android SDK build image" \
      org.opencontainers.image.source="https://github.com/MateeDevs/ci-setup/tree/master" \
      cz.matee.butterfree.variant="build" \
      cz.matee.butterfree.ubuntu.version="${UBUNTU_VERSION}" \
      cz.matee.butterfree.java.version="${JAVA_VERSION}" \
      cz.matee.butterfree.gradle.version="${GRADLE_VERSION}" \
      cz.matee.butterfree.kotlin.version="${KOTLIN_VERSION}" \
      cz.matee.butterfree.android.command-line-tools.version="${ANDROID_CMDLINE_TOOLS_VERSION}" \
      cz.matee.butterfree.android.build-tools.versions="${ANDROID_BUILD_TOOLS_VERSIONS}" \
      cz.matee.butterfree.android.platforms.versions="${ANDROID_PLATFORM_VERSIONS}" \
      cz.matee.butterfree.android.platform-tools.version="${ANDROID_PLATFORM_TOOLS_VERSION}"

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    JAVA_VERSION=${JAVA_VERSION} \
    JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64 \
    GRADLE_VERSION=${GRADLE_VERSION} \
    GRADLE_HOME=/opt/gradle \
    GRADLE_USER_HOME=/root/.gradle \
    KOTLIN_VERSION=${KOTLIN_VERSION} \
    KONAN_DATA_DIR=/root/.konan \
    KONAN_HOME=/opt/kotlin-native \
    ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    ANDROID_CMDLINE_TOOLS_VERSION=${ANDROID_CMDLINE_TOOLS_VERSION} \
    ANDROID_BUILD_TOOLS_VERSIONS=${ANDROID_BUILD_TOOLS_VERSIONS} \
    ANDROID_PLATFORM_VERSIONS=${ANDROID_PLATFORM_VERSIONS} \
    ANDROID_PLATFORM_TOOLS_VERSION=${ANDROID_PLATFORM_TOOLS_VERSION}

ENV PATH=${GRADLE_HOME}/bin:${KONAN_HOME}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}

RUN test "${TARGETARCH:-amd64}" = "amd64" || \
    (echo "butterfree currently supports only linux/amd64" >&2; exit 1)

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        locales \
        openjdk-${JAVA_VERSION}-jdk-headless \
        openssh-client \
        tar \
        unzip \
        wget \
        xz-utils \
        zip \
    && locale-gen en_US.UTF-8

RUN --mount=type=cache,target=/var/cache/butterfree \
    set -eux; \
    archive="/var/cache/butterfree/gradle-${GRADLE_VERSION}-bin.zip"; \
    if ! echo "${GRADLE_SHA256}  ${archive}" | sha256sum --check --status; then \
        curl --fail --location --retry 3 \
            --output "${archive}.tmp" \
            "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"; \
        mv "${archive}.tmp" "${archive}"; \
    fi; \
    echo "${GRADLE_SHA256}  ${archive}" | sha256sum --check; \
    unzip -q "${archive}" -d /opt; \
    mv "/opt/gradle-${GRADLE_VERSION}" "${GRADLE_HOME}"; \
    gradle --version

RUN --mount=type=cache,target=/var/cache/butterfree \
    set -eux; \
    filename="kotlin-native-prebuilt-linux-x86_64-${KOTLIN_VERSION}.tar.gz"; \
    archive="/var/cache/butterfree/${filename}"; \
    if ! echo "${KOTLIN_NATIVE_SHA256}  ${archive}" | sha256sum --check --status; then \
        curl --fail --location --retry 3 \
            --output "${archive}.tmp" \
            "https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/${filename}"; \
        mv "${archive}.tmp" "${archive}"; \
    fi; \
    echo "${KOTLIN_NATIVE_SHA256}  ${archive}" | sha256sum --check; \
    mkdir -p "${KONAN_HOME}" "${KONAN_DATA_DIR}"; \
    tar -xzf "${archive}" -C "${KONAN_HOME}" --strip-components=1; \
    ln -s "${KONAN_HOME}" \
        "${KONAN_DATA_DIR}/kotlin-native-prebuilt-linux-x86_64-${KOTLIN_VERSION}"; \
    test -x "${KONAN_HOME}/bin/konanc"

RUN --mount=type=cache,target=/var/cache/butterfree \
    set -eux; \
    filename="commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip"; \
    archive="/var/cache/butterfree/${filename}"; \
    if ! echo "${ANDROID_CMDLINE_TOOLS_SHA256}  ${archive}" | sha256sum --check --status; then \
        curl --fail --location --retry 3 \
            --output "${archive}.tmp" \
            "https://dl.google.com/android/repository/${filename}"; \
        mv "${archive}.tmp" "${archive}"; \
    fi; \
    echo "${ANDROID_CMDLINE_TOOLS_SHA256}  ${archive}" | sha256sum --check; \
    mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools" /root/.android; \
    unzip -q "${archive}" -d "${ANDROID_SDK_ROOT}/cmdline-tools"; \
    mv "${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools" \
       "${ANDROID_SDK_ROOT}/cmdline-tools/latest"; \
    touch /root/.android/repositories.cfg

RUN yes | sdkmanager --licenses >/dev/null

# Lists are comma-separated so Bake can replace all versions with one variable.
RUN --mount=type=cache,target=/root/.android/cache \
    bash -Eeuo pipefail -c ' \
        packages=("platform-tools"); \
        IFS="," read -ra build_tools <<< "${ANDROID_BUILD_TOOLS_VERSIONS}"; \
        IFS="," read -ra platforms <<< "${ANDROID_PLATFORM_VERSIONS}"; \
        for version in "${build_tools[@]}"; do \
            version="${version//[[:space:]]/}"; \
            [[ -n "${version}" ]] && packages+=("build-tools;${version}"); \
        done; \
        for version in "${platforms[@]}"; do \
            version="${version//[[:space:]]/}"; \
            [[ -n "${version}" ]] && packages+=("platforms;android-${version}"); \
        done; \
        sdkmanager --install "${packages[@]}"; \
        actual="$(adb version | sed -n "s/^Version \\([0-9.]*\\).*/\\1/p" | head -n 1)"; \
        [[ "${actual}" == "${ANDROID_PLATFORM_TOOLS_VERSION}" ]] || { \
            echo "Expected platform-tools ${ANDROID_PLATFORM_TOOLS_VERSION}, installed ${actual}" >&2; \
            exit 1; \
        } \
    '

WORKDIR /workspace


FROM android AS emulator

ARG DEBIAN_FRONTEND=noninteractive
ARG IMAGE_VERSION=development
ARG ANDROID_EMULATOR_VERSION=37.1.11
ARG EMULATOR_ARCH=x86_64
ARG EMULATOR_TARGET=google_apis_playstore
ARG EMULATOR_API_LEVEL=34
ARG EMULATOR_NAME=Pixel_7_Pro
ARG EMULATOR_DEVICE=pixel_7_pro
ARG MAESTRO_VERSION=2.9.0
ARG MAESTRO_SHA256=855bb2ce1399d82f4f4a73d84a4d945f70b0d43eb86127e027af82809f63f0bd

LABEL org.opencontainers.image.title="butterfree" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.description="Butterfree with an Android API ${EMULATOR_API_LEVEL} ${EMULATOR_ARCH} emulator and Maestro" \
      cz.matee.butterfree.variant="emulator" \
      cz.matee.butterfree.android.emulator.version="${ANDROID_EMULATOR_VERSION}" \
      cz.matee.butterfree.android.emulator.api="${EMULATOR_API_LEVEL}" \
      cz.matee.butterfree.android.emulator.arch="${EMULATOR_ARCH}" \
      cz.matee.butterfree.android.emulator.target="${EMULATOR_TARGET}" \
      cz.matee.butterfree.android.emulator.device="${EMULATOR_DEVICE}" \
      cz.matee.butterfree.maestro.version="${MAESTRO_VERSION}"

ENV EMULATOR_PACKAGE=system-images\;android-${EMULATOR_API_LEVEL}\;${EMULATOR_TARGET}\;${EMULATOR_ARCH} \
    EMULATOR_ARCH=${EMULATOR_ARCH} \
    EMULATOR_TARGET=${EMULATOR_TARGET} \
    EMULATOR_API_LEVEL=${EMULATOR_API_LEVEL} \
    EMULATOR_NAME=${EMULATOR_NAME} \
    EMULATOR_DEVICE=${EMULATOR_DEVICE} \
    ANDROID_AVD_HOME=/root/.android/avd \
    DISPLAY=:1 \
    QT_X11_NO_MITSHM=1

ENV ANDROID_EMULATOR_VERSION=${ANDROID_EMULATOR_VERSION} \
    MAESTRO_VERSION=${MAESTRO_VERSION} \
    PATH=/opt/maestro/bin:/usr/local/lib/butterfree/bin:${ANDROID_SDK_ROOT}/emulator:${PATH}

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
        bzip2 \
        fluxbox \
        fontconfig \
        fonts-noto-color-emoji \
        fonts-noto-core \
        fonts-noto-mono \
        libasound2 \
        libdbus-1-3 \
        libdbus-glib-1-2 \
        libdrm2 \
        libfontconfig1 \
        libgbm1 \
        libgl1 \
        libnss3 \
        libpulse0 \
        libx11-6 \
        libx11-xcb1 \
        libxcb1 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxi6 \
        libxkbcommon0 \
        libxrandr2 \
        libxrender1 \
        libxshmfence1 \
        libxtst6 \
        python3 \
        python3-pip \
        python3-venv \
        python3-virtualenv \
        wmctrl \
        x11-utils \
        x11vnc \
        xauth \
        xvfb \
    && fc-cache -f

RUN --mount=type=cache,target=/root/.android/cache \
    sdkmanager --install "${EMULATOR_PACKAGE}" "emulator" && \
    actual="$(emulator -version 2>&1 | sed -n 's/^Android emulator version \([0-9.]*\).*/\1/p' | head -n 1)" && \
    case "${actual}" in \
        "${ANDROID_EMULATOR_VERSION}"|"${ANDROID_EMULATOR_VERSION}.0") ;; \
        *) echo "Expected emulator ${ANDROID_EMULATOR_VERSION}, installed ${actual}" >&2; exit 1 ;; \
    esac && \
    echo "no" | avdmanager create avd \
        --force \
        --name "${EMULATOR_NAME}" \
        --device "${EMULATOR_DEVICE}" \
        --package "${EMULATOR_PACKAGE}" && \
    printf '\nhw.keyboard=yes\n' >> "${ANDROID_AVD_HOME}/${EMULATOR_NAME}.avd/config.ini"

COPY --chmod=0755 emu_scripts/ /usr/local/lib/butterfree/bin/

RUN --mount=type=cache,target=/var/cache/butterfree \
    set -eux; \
    archive="/var/cache/butterfree/maestro-${MAESTRO_VERSION}.zip"; \
    if ! echo "${MAESTRO_SHA256}  ${archive}" | sha256sum --check --status; then \
        curl --fail --location --retry 3 \
            --output "${archive}.tmp" \
            "https://github.com/mobile-dev-inc/Maestro/releases/download/cli-${MAESTRO_VERSION}/maestro.zip"; \
        mv "${archive}.tmp" "${archive}"; \
    fi; \
    echo "${MAESTRO_SHA256}  ${archive}" | sha256sum --check; \
    unzip -q "${archive}" -d /opt; \
    maestro --version; \
    python3 --version; \
    pip3 --version


# Building without --target produces the Android build-tooling variant.
FROM android AS butterfree
