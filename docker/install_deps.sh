#!/bin/bash

set -euxo pipefail

apt-get -qq update

apt-get -qq install --no-install-recommends -y \
    apt-transport-https \
    gnupg \
    wget \
    procps vainfo \
    unzip locales tzdata libxml2 xz-utils ca-certificates \
    curl \
    jq \
    python3-pip \
    ca-certificates

mkdir -p -m 600 /root/.gnupg

# add coral repo
wget --quiet -O /usr/share/keyrings/google-edgetpu.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/google-edgetpu.gpg] https://packages.cloud.google.com/apt coral-edgetpu-stable main" | tee /etc/apt/sources.list.d/coral-edgetpu.list
echo "libedgetpu1-max libedgetpu/accepted-eula select true" | debconf-set-selections


#echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" | tee /etc/apt/sources.list.d/coral-edgetpu.list
#curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
#apt-get -q update
#apt-get install -y libedgetpu1-std


# enable non-free repo
 sed -i -e's/ main/ main contrib non-free/g' /etc/apt/sources.list

# coral drivers
apt-get -qq update
apt-get -qq install --no-install-recommends --no-install-suggests -y \
    libedgetpu1-max python3-tflite-runtime python3-pycoral

#wget --quiet  https://files.pythonhosted.org/packages/2a/b6/5b7c8b247f612fbab8b2cf77228c7b0fa4c373c4c9fca40e30f88fbe93c4/tflite_runtime-2.11.0-cp39-cp39-manylinux2014_x86_64.whl
#wget --quiet  https://files.pythonhosted.org/packages/bf/75/c49f676ad2de36fa174b74d52bf6b2a199a54168ee550bbf85053578eb5c/tflite_runtime-2.11.0-cp39-cp39-manylinux2014_aarch64.whl
#wget --quiet   https://github.com/google-coral/pycoral/releases/download/v2.0.0/pycoral-2.0.0-cp36-cp36m-linux_x86_64.whl

#wget --quiet  https://github.com/google-coral/pycoral/releases/download/v2.0.0/pycoral-2.0.0-cp36-cp36m-linux_aarch64.whl

#pip3 debug --verbose

#pip3 install tflite-runtime
#pip3 install pycoral

#pip3 install tflite_runtime-2.11.0-cp39-cp39-manylinux2014_x86_64.whl
#pip3 install pycoral-2.0.0-cp36-cp36m-linux_x86_64.whl

# btbn-ffmpeg -> amd64
if [[ "${TARGETARCH}" == "amd64" ]]; then
    mkdir -p /usr/lib/btbn-ffmpeg
    wget -qO btbn-ffmpeg.tar.xz "https://github.com/BtbN/FFmpeg-Builds/releases/download/autobuild-2022-07-31-12-37/ffmpeg-n5.1-2-g915ef932a3-linux64-gpl-5.1.tar.xz"
    tar -xf btbn-ffmpeg.tar.xz -C /usr/lib/btbn-ffmpeg --strip-components 1
    rm -rf btbn-ffmpeg.tar.xz /usr/lib/btbn-ffmpeg/doc /usr/lib/btbn-ffmpeg/bin/ffplay
fi

# ffmpeg -> arm64
if [[ "${TARGETARCH}" == "arm64" ]]; then
    # add raspberry pi repo
    # Update package list
     apt-get update

    # Install necessary packages for adding PPA
     apt-get install -y software-properties-common gpg gpg-agent udev
     
    # Add the PPA
     add-apt-repository -y ppa:liujianfeng1994/rockchip-multimedia
     cat /etc/apt/sources.list.d/liujianfeng1994-ubuntu-rockchip-multimedia-mantic.list
    # edit /etc/apt/sources.list.d/liujianfeng1994-ubuntu-rockchip-multimedia-jammy.list
     sed -i 's/mantic/jammy/g' /etc/apt/sources.list.d/liujianfeng1994-ubuntu-rockchip-multimedia-mantic.list
     apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 8065BE1FC67AABDE



    # Update package list again
     apt-get update

    # Install the required packages
     apt-get install -y rockchip-multimedia-config gstreamer1.0-rockchip1 ffmpeg

    # Clean up the package cache
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
fi

# arch specific packages
if [[ "${TARGETARCH}" == "amd64" ]]; then
    # Use debian testing repo only for hwaccel packages
    echo 'deb http://deb.debian.org/debian testing main non-free' >/etc/apt/sources.list.d/debian-testing.list
    apt-get -qq update
    # intel-opencl-icd specifically for GPU support in OpenVino
    apt-get -qq install --no-install-recommends --no-install-suggests -y \
        intel-opencl-icd \
        mesa-va-drivers libva-drm2 intel-media-va-driver-non-free i965-va-driver libmfx1 radeontop intel-gpu-tools
    # something about this dependency requires it to be installed in a separate call rather than in the line above
    apt-get -qq install --no-install-recommends --no-install-suggests -y \
        i965-va-driver-shaders
    rm -f /etc/apt/sources.list.d/debian-testing.list
fi

if [[ "${TARGETARCH}" == "arm64" ]]; then
    apt-get -qq install --no-install-recommends --no-install-suggests -y \
        libva-drm2 mesa-va-drivers
fi

apt-get purge gnupg apt-transport-https wget xz-utils -y
apt-get clean autoclean -y
apt-get autoremove --purge -y
rm -rf /var/lib/apt/lists/*
