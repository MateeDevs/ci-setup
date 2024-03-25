# Example build commands:
# $ docker build -t j17-android-twine .
# $ docker build --build-arg ANDROID_IMAGE=j17-android -t j17-android-twine .

# Java 17 Android image is default
ARG ANDROID_IMAGE=j17-android

FROM ${ANDROID_IMAGE}

# Get libs for Ruby
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*
    

# Install Ruby using a package manager
RUN apt-get update && \
    apt-get install -y ruby-full && \
    rm -rf /var/lib/apt/lists/*
    
# Verify Ruby installation
RUN ruby -v

#Install Twine
RUN gem install twine
