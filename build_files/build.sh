#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# Base utilities
dnf5 install -y tmux

### Windows App Support
# Wine allows running Windows applications directly on Linux
# winetricks provides easy installation of Windows runtimes and libraries
# cabextract is required by many winetricks components to extract Windows installers
dnf5 install -y \
    wine \
    winetricks \
    cabextract

### Windows-like Applications (Linux native equivalents)
# LibreOffice  — Microsoft Office equivalent (Writer=Word, Calc=Excel, Impress=PowerPoint)
# Thunderbird  — Microsoft Outlook equivalent (email + calendar)
# VLC          — Windows Media Player equivalent (video/audio player)
dnf5 install -y \
    libreoffice \
    thunderbird \
    vlc

### Microsoft-compatible fonts
# Liberation fonts are metric-compatible replacements for common Microsoft fonts
# (Arial→Liberation Sans, Times New Roman→Liberation Serif, Courier New→Liberation Mono)
# This ensures documents created on Windows render correctly on this system
dnf5 install -y \
    liberation-fonts \
    liberation-fonts-common

### Windows-like KDE Plasma theming
# Kvantum is a theme engine for Qt/KDE that enables pixel-perfect Windows-style themes.
# After first boot, users can install a Windows 11 Kvantum theme from the KDE Store:
# https://store.kde.org/browse?cat=123&ord=rating
dnf5 install -y kvantum

#### Enable System Unit Files

systemctl enable podman.socket
