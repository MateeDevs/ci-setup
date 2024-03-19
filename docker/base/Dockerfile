# Example build commands:
# $ docker build -t base-tools .

FROM ubuntu:22.04

# Avoid being asked interactive questions when installing packages
ARG DEBIAN_FRONTEND=noninteractive

#Install tools
RUN apt-get update && apt-get install -y \
    unzip \
    wget \
    curl \
    git \
    tar && \
    rm -rf /var/lib/apt/lists/*
