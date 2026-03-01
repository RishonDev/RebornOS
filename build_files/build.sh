#!/bin/bash

# set -ouex pipefail ensures the build fails immediately on any error,
# undefined variable, or failed pipeline stage — no silent partial installs.
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

### Apply Win11OS SDDM login-screen theme
# SDDM is the display manager — this makes the login / lock screen look like
# the corresponding Windows version. The sed replacements in
# setup-version-branches.yml will update "Win11OS" to "Win10OS" or "Win7OS".
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/theme.conf << 'EOF'
[Theme]
Current=Win11OS
EOF

### Pre-configure KDE Plasma theming for new users
# Files placed in /etc/skel are copied to every new user's home on first login.
# Writing these files ensures the desktop looks like the corresponding Windows
# version out of the box without requiring any manual configuration step.
#   plasmarc              — sets the Plasma desktop/panel/widget theme
#   kwinrc                — activates the matching Aurorae window decoration
#   kdeglobals            — sets color scheme, fonts, icon theme, widget style,
#                           and records the look-and-feel package for all Qt/KDE
#                           apps (Dolphin, System Settings, KCalc, Kate, etc.)
#   Kvantum/kvantum.kvconfig — selects the Qt application style
# The sed replacements in setup-version-branches.yml will substitute "Win11OS"
# with "Win10OS" or "Win7OS" throughout, keeping all three branches in sync.
cat > /etc/skel/.config/plasmarc << 'EOF'
[Theme]
name=Win11OS-dark
EOF

cat > /etc/skel/.config/kwinrc << 'EOF'
[org.kde.kdecoration2]
library=org.kde.kwin.aurorae
NoPlugin=false
theme=__aurorae__svg__Win11OS-dark
EOF

cat > /etc/skel/.config/kdeglobals << 'EOF'
[General]
ColorScheme=Win11OS-dark
Name=Win11OS-dark
font=Liberation Sans,10,-1,5,50,0,0,0,0,0
menuFont=Liberation Sans,10,-1,5,50,0,0,0,0,0
toolBarFont=Liberation Sans,9,-1,5,50,0,0,0,0,0
activeFont=Liberation Sans,10,-1,5,57,0,0,0,0,0
smallestReadableFont=Liberation Sans,8,-1,5,50,0,0,0,0,0
fixed=Liberation Mono,10,-1,5,50,0,0,0,0,0

[Icons]
Theme=Fluent-dark

[KDE]
LookAndFeelPackage=com.github.yeyushengfan258.Win11OS-kde
widgetStyle=kvantum-dark
EOF

mkdir -p /etc/skel/.config/Kvantum
cat > /etc/skel/.config/Kvantum/kvantum.kvconfig << 'EOF'
[%General]
theme=Win11OS-dark
EOF

### GTK application theming
# GTK apps (Firefox file picker, LibreOffice dialogs, Nautilus if installed, etc.)
# pick up icon theme and font from these files, keeping them visually consistent
# with the KDE apps above.  Firefox itself is kept as-is — only its file picker
# and native GTK dialogs inherit the icon set and font.
mkdir -p /etc/skel/.config/gtk-3.0 \
         /etc/skel/.config/gtk-4.0

cat > /etc/skel/.config/gtk-3.0/settings.ini << 'EOF'
[Settings]
gtk-icon-theme-name=Fluent-dark
gtk-font-name=Liberation Sans 10
EOF

cat > /etc/skel/.config/gtk-4.0/settings.ini << 'EOF'
[Settings]
gtk-icon-theme-name=Fluent-dark
gtk-font-name=Liberation Sans 10
EOF

### First-login look-and-feel activation script
# plasma-apply-lookandfeel applies the full look-and-feel package (panel layout,
# task-switcher, window buttons, wallpaper) — things that cannot be set via
# static config files alone. A marker file prevents it running on subsequent logins.
mkdir -p /etc/skel/.config/autostart-scripts
cat > /etc/skel/.config/autostart-scripts/apply-look-and-feel.sh << 'EOF'
#!/bin/bash
# Apply Win11OS-kde look-and-feel on first login, then disable this script.
MARKER="${HOME}/.config/.win11os-look-and-feel-applied"
if [ ! -f "${MARKER}" ]; then
    plasma-apply-lookandfeel --apply com.github.yeyushengfan258.Win11OS-kde
    touch "${MARKER}"
fi
EOF
chmod +x /etc/skel/.config/autostart-scripts/apply-look-and-feel.sh

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
