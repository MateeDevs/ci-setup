# Example build commands:
# $ docker build -t base-tools .

FROM ubuntu:22.04

# Avoid being asked interactive questions when installing packages
ARG DEBIAN_FRONTEND=noninteractive

# Set locale environment variables
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install locale packages
RUN apt-get update && apt-get install -y locales && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8
    
#Install tools
RUN apt-get update && apt-get install -y \
    unzip \
    wget \
    curl \
    git \
    tar && \
    rm -rf /var/lib/apt/lists/*
