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
dnf5 install -y kvantum

### Windows 11 Kvantum theme
# Win11OS-kde provides a pixel-accurate Windows 11 look for KDE/Qt applications via Kvantum.
# The theme is installed system-wide so it is available to all users out of the box.
# Pinned to commit 9f021c3e to ensure reproducible builds.
curl -L https://github.com/yeyushengfan258/Win11OS-kde/archive/9f021c3e71da7baf59a0614ab858d53b1e455fd5.tar.gz \
    | tar xz -C /tmp
mkdir -p /usr/share/Kvantum
cp -r /tmp/Win11OS-kde-9f021c3e71da7baf59a0614ab858d53b1e455fd5/Kvantum/Win11OS-dark  /usr/share/Kvantum/
cp -r /tmp/Win11OS-kde-9f021c3e71da7baf59a0614ab858d53b1e455fd5/Kvantum/Win11OS-light /usr/share/Kvantum/
rm -rf /tmp/Win11OS-kde-9f021c3e71da7baf59a0614ab858d53b1e455fd5

### Windows 11 icon theme
# Fluent icon theme mirrors the Windows 11 icon design language system-wide.
# Pinned to release tag 2025-08-21 (commit d483abe8) for reproducible builds.
curl -L https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2025-08-21.tar.gz \
    | tar xz -C /tmp
bash /tmp/Fluent-icon-theme-2025-08-21/install.sh -d /usr/share/icons
rm -rf /tmp/Fluent-icon-theme-2025-08-21

### Windows built-in app equivalents
# kcalc     — Calculator
# spectacle — Snipping Tool / screenshot utility
# gwenview  — Photos / image viewer
# okular    — Microsoft Edge PDF reader / Windows Reader
# ark       — File Explorer zip support / 7-Zip equivalent
# kate      — Notepad / Notepad++ equivalent
dnf5 install -y \
    kcalc \
    spectacle \
    gwenview \
    okular \
    ark \
    kate

#### Enable System Unit Files

systemctl enable podman.socket
