#!/bin/bash
# Copyright 2024 Antmicro
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


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

