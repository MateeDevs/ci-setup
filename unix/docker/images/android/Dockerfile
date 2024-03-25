# Example build commands:
# $ docker build -t j17-android .
# $ docker build --build-arg JAVA_IMAGE=java-17 -t j17-android .

# Java 17 image is default
ARG JAVA_IMAGE=java-17

FROM ${JAVA_IMAGE}

ENV ANDROID_SDK_ROOT="/usr/local/android-sdk"
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools

ENV CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

# Download Android SDK
RUN mkdir "$ANDROID_SDK_ROOT" .android \
    && mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools" \
    && curl -o commandlinetools.zip $CMDLINE_TOOLS_URL \
    && unzip commandlinetools.zip -d "$ANDROID_SDK_ROOT/cmdline-tools" \
    && mv "$ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest" \
    && rm commandlinetools.zip

# Accept all licenses
RUN yes | sdkmanager --licenses

RUN echo y | sdkmanager "tools" && \
    echo y | sdkmanager "platform-tools" && \
    echo y | sdkmanager "build-tools;34.0.0" && \
    echo y | sdkmanager "build-tools;33.0.2" && \
    echo y | sdkmanager "build-tools;33.0.1" && \
    echo y | sdkmanager "build-tools;32.1.0-rc1" && \	
    echo y | sdkmanager "build-tools;30.0.3"

RUN echo y | sdkmanager "platforms;android-34" && \
    echo y | sdkmanager "platforms;android-33" && \
    echo y | sdkmanager "platforms;android-32" && \
    echo y | sdkmanager "platforms;android-31"
