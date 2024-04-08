#!/bin/bash

# Downloads packages from debian repositories
INST="env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends"
apt-get -y update && $INST \
    automake \
    autotools-dev \
    binutils \
    bison \
    build-essential \
    ca-certificates \
    ccache \
    clang \
    cmake \
    debhelper \
    devscripts \
    flex \
    g++ \
    gawk \
    gcc \
    git \
    git-lfs \
    kmod \
    lcov \
    libc6-dbg \
    libboost-filesystem-dev \
    libboost-python-dev \
    libboost-system-dev \
    libffi-dev \
    libgomp1 \
    libomp-dev \
    libpcre2-dev \
    libpcre3-dev \
    libreadline-dev \
    libtbb-dev \
    libtcl \
    make \
    pkg-config \
    python3-dev \
    python3-pip \
    python3-requests \
    tcl-dev \
    tcllib \
    tcl-tclreadline \
    time \
    unzip \
    wget \
    zlib1g-dev

