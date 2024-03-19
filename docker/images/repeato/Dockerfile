# Example build commands:
# $ docker build -t repeato-android .
# $ docker build --build-arg ANDROID_IMAGE=j17-android -t repeato-android .

# Java 17 Android image with twine is default
ARG ANDROID_IMAGE=j17-android

FROM ${ANDROID_IMAGE}

ENV KOTLIN_VERSION 1.8.10
ENV KOTLIN_COMPILER kotlin-native-prebuilt-linux-x86_64-${KOTLIN_VERSION}

RUN wget "https://download.jetbrains.com/kotlin/native/builds/releases/${KOTLIN_VERSION}/linux-x86_64/${KOTLIN_COMPILER}.tar.gz" -q --show-progress --progress=bar:force 2>&1 &&\
    mkdir -p /root/.konan/${KOTLIN_COMPILER} &&\
    tar -xzvf ${KOTLIN_COMPILER}.tar.gz -C /root/.konan &&\
    rm ${KOTLIN_COMPILER}.tar.gz
    
COPY . /gradle

# ./gradlew --version installs gradle
RUN ./gradle/gradlew --version
   
