FROM base-tools

# Example build commands:
# $ docker build -t java-17 .
# $ docker build --build-arg VERSION=17 -t java-17 .

# Java 17 is default
ARG VERSION=17

# Install java ${VERSION}
RUN apt-get update && apt-get install -y \
    openjdk-${VERSION}-jdk

# Set JAVA_HOME (and related) environment variable. This will be set to our
# default Java version of ${VERSION} but the user would need to reset it when changing
# JAVA versions.
ENV JAVA_HOME=/usr/lib/jvm/java-${VERSION}-openjdk-amd64
ENV JDK_HOME=${JAVA_HOME}
ENV JRE_HOME=${JDK_HOME}
