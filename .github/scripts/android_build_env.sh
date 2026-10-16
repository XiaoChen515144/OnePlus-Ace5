#!/usr/bin/env bash

# Copyright (C) 2018 Harsh 'MSF Jarvis' Shandilya
# Copyright (C) 2018 Akhil Narang
# SPDX-License-Identifier: GPL-3.0-only

# Script to setup an AOSP Build environment on Ubuntu and Linux Mint
# Updated for Ubuntu 26.04 LTS (Resolute Raccoon)

LATEST_MAKE_VERSION="4.3"
UBUNTU_16_PACKAGES="libesd0-dev"
UBUNTU_20_PACKAGES="libncurses5 curl python-is-python3"
UBUNTU_24_PACKAGES="libncurses6 curl python-is-python3"
UBUNTU_26_PACKAGES="libncurses6 curl python-is-python3 libsdl2-dev"
DEBIAN_10_PACKAGES="libncurses5"
DEBIAN_11_PACKAGES="libncurses5"
PACKAGES=""

sudo apt install software-properties-common -y
sudo apt update
sudo apt install lsb-release -y

LSB_RELEASE="$(lsb_release -d | cut -d ':' -f 2 | sed -e 's/^[[:space:]]*//')"

if [[ ${LSB_RELEASE} =~ "Mint 18" || ${LSB_RELEASE} =~ "Ubuntu 16" ]]; then
    PACKAGES="${UBUNTU_16_PACKAGES}"
elif [[ ${LSB_RELEASE} =~ "Ubuntu 20" || ${LSB_RELEASE} =~ "Ubuntu 21" || ${LSB_RELEASE} =~ "Ubuntu 22" || ${LSB_RELEASE} =~ 'Pop!_OS 2' ]]; then
    PACKAGES="${UBUNTU_20_PACKAGES}"
elif [[ ${LSB_RELEASE} =~ "Ubuntu 23" || ${LSB_RELEASE} =~ "Ubuntu 24" ]]; then
    PACKAGES="${UBUNTU_24_PACKAGES}"
elif [[ ${LSB_RELEASE} =~ "Ubuntu 26" ]]; then
    PACKAGES="${UBUNTU_26_PACKAGES}"
elif [[ ${LSB_RELEASE} =~ "Debian GNU/Linux 10" ]]; then
    PACKAGES="${DEBIAN_10_PACKAGES}"
elif [[ ${LSB_RELEASE} =~ "Debian GNU/Linux 11" ]]; then
    PACKAGES="${DEBIAN_11_PACKAGES}"
fi

# FIX 1: Replaced bare "libxml2" with "libxml2-dev"
#   On Ubuntu 26.04, libxml2 had an ABI break (soname .so.2 -> .so.16).
#   The runtime package is now "libxml2-16"; bare "libxml2" is virtual with
#   no install candidate. "libxml2-dev" still exists and pulls the runtime lib.
sudo DEBIAN_FRONTEND=noninteractive \
    apt install \
    adb autoconf automake axel bc bison build-essential \
    ccache clang cmake curl expat fastboot flex g++ \
    g++-multilib gawk gcc gcc-multilib git git-lfs gnupg gperf \
    htop imagemagick lib32ncurses-dev lib32z1-dev libc6-dev libcap-dev \
    libexpat1-dev libgmp-dev '^liblz4-.*' '^liblzma.*' libmpc-dev libmpfr-dev libncurses-dev \
    libssl-dev libtool libxml2-dev libxml2-utils '^lzma.*' lzop \
    maven ncftp patch patchelf pkg-config pngcrush \
    pngquant re2c schedtool squashfs-tools subversion \
    texinfo unzip w3m xsltproc zip zlib1g-dev lzip \
    libxml-simple-perl libswitch-perl apt-utils wget \
    ${PACKAGES} -y

sudo apt install python3 python3-dev python3-pip -y

if ! command -v python &> /dev/null; then
    sudo ln -sf /usr/bin/python3 /usr/bin/python
fi

echo -e "Installing GitHub CLI"
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install -y gh

echo -e "Setting up udev rules for adb!"
sudo curl --create-dirs -L -o /etc/udev/rules.d/51-android.rules https://raw.githubusercontent.com/M0Rf30/android-udev-rules/master/51-android.rules
sudo chmod 644 /etc/udev/rules.d/51-android.rules
sudo chown root /etc/udev/rules.d/51-android.rules

# FIX 2: systemd renamed udev.service -> systemd-udevd.service on 26.04
#        Fall back gracefully for older Ubuntu versions
if systemctl list-unit-files | grep -q 'systemd-udevd.service'; then
    sudo systemctl restart systemd-udevd
else
    sudo systemctl restart udev
fi

# FIX 3: Guard against missing make.sh
if [[ "$(command -v make)" ]]; then
    makeversion="$(make -v | head -1 | awk '{print $3}')"
    if [[ ${makeversion} != "${LATEST_MAKE_VERSION}" ]]; then
        MAKE_SH="$(dirname "$0")/make.sh"
        if [[ -f "${MAKE_SH}" ]]; then
            echo "Installing make ${LATEST_MAKE_VERSION} instead of ${makeversion}"
            bash "${MAKE_SH}" "${LATEST_MAKE_VERSION}"
        else
            echo "WARNING: make ${makeversion} is installed but make ${LATEST_MAKE_VERSION} is recommended."
            echo "         make.sh not found at ${MAKE_SH} — skipping make upgrade."
            echo "         To build make 4.3 manually:"
            echo "           wget https://ftp.gnu.org/gnu/make/make-4.3.tar.gz"
            echo "           tar xzf make-4.3.tar.gz && cd make-4.3"
            echo "           ./configure && make -j\$(nproc) && sudo make install"
        fi
    fi
fi

echo "Installing repo"
sudo curl --create-dirs -L -o /usr/local/bin/repo https://storage.googleapis.com/git-repo-downloads/repo
sudo chmod a+rx /usr/local/bin/repo