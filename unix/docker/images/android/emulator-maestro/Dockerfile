# Example build commands:
# $ docker build -t j17-android-emulator .
# $ docker build --build-arg ANDROID_IMAGE=j17-android -t j17-android-emulator .

# Example run commands:
# $ docker run -it -d -p 5900:5900 --name androidContainer -e VNC_PASSWORD=123 --privileged j17-android-emulator
# $ docker exec --privileged -it androidContainer bash -c "./start_vnc.sh"

# Java 21 Android image is default
ARG ANDROID_IMAGE=j21-android

FROM ${ANDROID_IMAGE}

# Avoid being asked interactive questions when installing packages
ARG DEBIAN_FRONTEND=noninteractive

# Install packages
RUN apt-get update && apt-get install -y \
    bzip2 \
    libdrm-dev \
    libxkbcommon-dev \
    libgbm-dev \
    libasound-dev \
    libnss3 \
    libxcursor1 \
    libpulse-dev \
    libxshmfence-dev \
    xauth \
    xvfb \
    x11vnc \
    fluxbox \
    wmctrl \
    python3 \
    python3-pip \
    libdbus-glib-1-2 && \
    rm -rf /var/lib/apt/lists/*

# Define emulator parameters
ARG ARCH=x86_64 \
    TARGET=google_apis_playstore \
    EMULATOR_API_LEVEL=34 \
    EMULATOR_NAME="Pixel_7_Pro" \
    EMULATOR_DEVICE="pixel_7_pro"

ENV EMULATOR_PACKAGE=system-images;android-${EMULATOR_API_LEVEL};${TARGET};${ARCH} \
    EMULATOR_NAME=$EMULATOR_NAME \
    EMULATOR_DEVICE=$EMULATOR_DEVICE \
    ANDROID_AVD_HOME="/root/.android/avd"

# Install emulator tools
RUN sdkmanager "${EMULATOR_PACKAGE}" "emulator"

# List possible devices
RUN avdmanager list device

# Create required emulator AVD
RUN echo "no" | avdmanager create avd --force --name "${EMULATOR_NAME}" --device "${EMULATOR_DEVICE}" --package "${EMULATOR_PACKAGE}"

COPY . /

# Add permissions for emulator launch scripts ans VNC start script
RUN chmod a+x /emu_scripts/start_emu_headless.sh && \
    chmod a+x /emu_scripts/start_emu.sh && \
    chmod a+x /emu_scripts/start_vnc.sh

# Add script and emulator to the PATH
ENV PATH=$PATH:/emu_scripts:$ANDROID_SDK_ROOT/emulator

# Install pip
RUN pip3 install virtualenv

# Install Maestro
ENV MAESTRO_VERSION 1.41.0

RUN mkdir -p /opt/maestro && \
wget -q -O /tmp/${MAESTRO_VERSION} "https://github.com/mobile-dev-inc/maestro/releases/download/cli-${MAESTRO_VERSION}/maestro.zip" && \
unzip -q /tmp/${MAESTRO_VERSION} -d /opt/ && \
rm /tmp/${MAESTRO_VERSION}
ENV PATH=/opt/maestro/bin:${PATH}

# Install fonts for Maestro recording
RUN apt-get update && apt-get install -y \
	fonts-noto \
	fonts-noto-mono \
	fonts-noto-color-emoji && fc-cache -f -v

