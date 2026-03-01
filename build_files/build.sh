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
# protontricks extends Proton (already shipped by Bazzite/Steam) with per-game Winetricks overrides
dnf5 install -y \
    wine \
    winetricks \
    cabextract \
    protontricks

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

### Windows 11 full KDE theme suite
# Win11OS-kde's install.sh installs all KDE theming components system-wide in one pass:
#   • Kvantum theme       — Qt/KDE application chrome (Win11OS-dark + Win11OS-light)
#   • Aurorae decoration  — window title bar with Windows 11 close/min/max buttons
#   • Color scheme        — system-wide accent and palette matching Windows 11 blue
#   • Plasma desktop theme — panel, task-switcher, and widget styling
#   • Look-and-feel package — bundles panel layout (bottom bar, centered icons)
#   • Wallpaper            — official-style Windows 11 wallpapers
# Pinned to commit 9f021c3e for reproducible builds.
curl -L https://github.com/yeyushengfan258/Win11OS-kde/archive/9f021c3e71da7baf59a0614ab858d53b1e455fd5.tar.gz \
    | tar xz -C /tmp
# install.sh detects UID=0 (root) and installs to /usr/share/* system-wide paths.
# No interactive input or extra flags needed for a root system-wide install.
bash /tmp/Win11OS-kde-9f021c3e71da7baf59a0614ab858d53b1e455fd5/install.sh
rm -rf /tmp/Win11OS-kde-9f021c3e71da7baf59a0614ab858d53b1e455fd5

### Windows 11 icon theme
# Fluent icon theme mirrors the Windows 11 icon design language system-wide.
# Pinned to release tag 2025-08-21 (commit d483abe8) for reproducible builds.
curl -L https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2025-08-21.tar.gz \
    | tar xz -C /tmp
bash /tmp/Fluent-icon-theme-2025-08-21/install.sh -d /usr/share/icons
rm -rf /tmp/Fluent-icon-theme-2025-08-21

### Windows Explorer-like Dolphin file manager
# Configure Dolphin with a Windows Explorer-like layout for every new user via /etc/skel:
#   • Details view (Name, Size, Date Modified, Type columns)  — like Explorer's default
#   • Breadcrumb navigation bar                               — like Explorer's address bar
#   • Places panel on the left                                — like Explorer's navigation pane
#   • Status bar at the bottom                                — shows item count and total size
#   • Menu bar hidden                                         — like modern Explorer
mkdir -p /etc/skel/.config \
         /etc/skel/.local/share/dolphin/view_properties/global

cat > /etc/skel/.config/dolphinrc << 'EOF'
[General]
BrowseThroughArchives=false
ConfirmClosingMultipleTabs=true
EditableUrl=false
HomeUrl=
OpenExternallyCalledFolderInNewTab=false
RememberOpenedTabs=true
ShowFullPath=false
ShowSpaceInfo=true
SortingChoice=CaseSensitiveSorting
UseTabForSwitchingSplitView=false
Version=202

[MainWindow]
MenuBar=Disabled
ToolBarsMovable=Disabled

[PreviewSettings]
Plugins=audiothumbnail,blenderthumbnail,comicbookthumbnail,djvuthumbnail,ebookthumbnail,exrthumbnail,fontthumbnail,imagethumbnail,jpegthumbnail,kraorathumbnail,windowsexethumbnail,windowsimagethumbnail,opendocumentthumbnail,paddingthumbnail,svgthumbnail,textthumbnail

[StatusBar]
Visible=true
EOF

# Default to Details view (ViewMode=1) — matches Windows Explorer's default view
cat > /etc/skel/.local/share/dolphin/view_properties/global/.directory << 'EOF'
[Dolphin]
HiddenFilesShown=false
PreviewsShown=true
SortFoldersFirst=true
SortOrder=0
SortRole=name
ViewMode=1
EOF

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
