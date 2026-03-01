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
# kcalc       — Calculator
# spectacle   — Snipping Tool / screenshot utility
# gwenview    — Photos / image viewer
# okular      — Microsoft Edge PDF reader / Windows Reader
# ark         — File Explorer zip support / 7-Zip equivalent
# kate        — Notepad / Notepad++ equivalent
# kolourpaint — MS Paint equivalent
# traceroute  — tracert equivalent (Windows network diagnostic)
dnf5 install -y \
    kcalc \
    spectacle \
    gwenview \
    okular \
    ark \
    kate \
    kolourpaint \
    traceroute

### Windows Store — KDE Discover rebranded
# KDE Discover (plasma-discover) is the graphical software centre for Plasma.
# Override its desktop entry so it appears as "Windows Store" in the
# application launcher, taskbar, and window title, giving users a familiar
# entry point for browsing and installing software — mirroring the
# Microsoft Store experience shipped with Windows 10/11.
# The Fluent icon theme (installed above) ships a "plasmadiscover" icon that
# closely resembles the Windows Store shopping-bag glyph.
cat > /usr/share/applications/org.kde.discover.desktop << 'EOF'
[Desktop Entry]
Name=Windows Store
GenericName=Software Center
Comment=Browse and install apps, games, and more
Exec=plasma-discover %u
Icon=plasmadiscover
Terminal=false
Type=Application
Categories=Qt;KDE;PackageManager;
MimeType=appstream://;snap://;
Keywords=Store;Shop;Windows;Microsoft;App;Games;
X-KDE-Protocols=appstream,snap
StartupNotify=true
EOF

### Microsoft PowerShell
# PowerShell ships with every Windows 10/11 system and is the most authentic
# Windows command-line experience available on Linux.
# Installed from Microsoft's official RHEL 9 package repository.
rpm --import https://packages.microsoft.com/keys/microsoft.asc
cat > /etc/yum.repos.d/microsoft-powershell.repo << 'EOF'
[microsoft-powershell]
name=Microsoft PowerShell
baseurl=https://packages.microsoft.com/rhel/9.0/prod/
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
# Pre-create the PowerShell install directory before the RPM unpacks its files.
# Without this, cpio fails when /opt is still a symlink to /var/opt in some
# base images (the Containerfile already converts /opt to a real directory, but
# this explicit mkdir is an extra safety net and ensures proper ownership).
mkdir -p /opt/microsoft/powershell/7
dnf5 install -y powershell

### Set PowerShell as the default login shell for new users
# bash remains fully available at /bin/bash as a fallback — scripts that use
# #!/bin/bash or invoke bash directly are completely unaffected.
# The PowerShell RPM registers /usr/bin/pwsh in /etc/shells; this line is a
# safety net in case it doesn't on this version.
grep -qxF '/usr/bin/pwsh' /etc/shells || echo '/usr/bin/pwsh' >> /etc/shells
# useradd (and the Anaconda installer) reads SHELL from /etc/default/useradd
# when creating new user accounts, so the first user gets pwsh by default.
sed -i 's|^SHELL=.*|SHELL=/usr/bin/pwsh|' /etc/default/useradd

### Windows PowerShell system-wide profile
# Runs for every user who opens pwsh.
# • Shows the "Windows PowerShell / Copyright" banner matching the real experience
# • Provides a "PS C:\Users\username\path>" prompt
# • Defines a winget function that wraps rpm-ostree and reminds the user to reboot
mkdir -p /opt/microsoft/powershell/7
cat > /opt/microsoft/powershell/7/profile.ps1 << 'EOF'
Write-Host ""
Write-Host "Windows PowerShell"
Write-Host "Copyright (C) Microsoft Corporation. All rights reserved."
Write-Host ""

# Windows-style "PS C:\Users\username\subdir>" prompt
function prompt {
    $p = $PWD.Path
    $p = $p -replace [regex]::Escape($HOME), "C:\Users\$env:USER"
    if ($p -notmatch '^C:\\') { $p = 'C:' + $p }
    $p = $p -replace '/', '\'
    "PS $p> "
}

# winget wraps rpm-ostree and reminds the user to reboot after each command
function winget {
    rpm-ostree @args
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Reboot your system to apply the changes" -ForegroundColor Green
    }
}
EOF

### KDE Konsole default profile — Windows PowerShell
# Pre-seeding these skel files makes Konsole open pwsh automatically for every
# new user, so the terminal greets them with a Windows PowerShell session.
mkdir -p /etc/skel/.local/share/konsole

cat > /etc/skel/.local/share/konsole/Windows-PowerShell.profile << 'EOF'
[Appearance]
ColorScheme=Linux
Font=Liberation Mono,10,-1,5,50,0,0,0,0,0

[General]
Command=/usr/bin/pwsh -NoLogo
Name=Windows PowerShell
Parent=FALLBACK/
TerminalColumns=120
TerminalRows=30
EOF

cat > /etc/skel/.config/konsolerc << 'EOF'
[Desktop Entry]
DefaultProfile=Windows-PowerShell.profile
EOF

### Windows-compatible bash aliases
# Applied system-wide via /etc/bashrc.d/ so every bash session (terminal, SSH,
# scripts invoked without pwsh) gets Windows-familiar commands alongside their
# Unix equivalents. Also sets a "PS C:\path>" prompt to match PowerShell.
mkdir -p /etc/bashrc.d
cat > /etc/bashrc.d/windows-shell.bash << 'EOF'
# ── Windows-compatible commands for bash ─────────────────────────────────────

# File / directory operations
alias dir='ls -la --color=auto'
alias copy='cp -i'
alias xcopy='cp -ri'
alias move='mv -i'
alias del='rm -i'
alias erase='rm -i'
alias ren='mv'
alias md='mkdir -p'
alias rd='rmdir'
alias cls='clear'
alias type='cat'

# System / network
alias ver='echo "RebornOS [$(uname -r)]"'
alias ipconfig='ip addr show'
alias netstat='ss -tulnp'
alias tasklist='ps aux'
alias tracert='traceroute'
alias ping='ping -c 4'
alias where='which'
alias findstr='grep -r'
alias path='echo "$PATH" | tr ":" "\n"'
alias systeminfo='uname -a && echo && cat /etc/os-release'

# App shortcuts matching Windows built-ins
alias notepad='kate'
alias explorer='dolphin'
alias calc='kcalc'
alias mspaint='kolourpaint'
alias wordpad='libreoffice --writer'
alias store='plasma-discover'
alias winstore='plasma-discover'

# taskkill — kill by PID or by process name (like: taskkill /F /IM app.exe)
taskkill() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: taskkill <PID|name>" >&2; return 1
    fi
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        kill "$1"
    else
        pkill -f "$1"
    fi
}

# winget — wraps rpm-ostree; reminds the user to reboot after each command
winget() {
    rpm-ostree "$@"
    local _exit=$?
    if [[ $_exit -eq 0 ]]; then
        printf '\e[32mReboot your system to apply the changes\e[0m\n'
    fi
    return $_exit
}

# Windows PowerShell-style prompt: "PS C:\Users\username\subdir>"
_win_path() {
    local p
    p="$(pwd)"
    p="${p/#$HOME/C:\\Users\\$USER}"   # /home/user  → C:\Users\user
    [[ "$p" == /* ]] && p="C:${p}"    # other /paths → C:\paths
    printf '%s' "${p//\//\\}"          # / → \
}
PS1='PS $(_win_path)> '
EOF

### Custom OS branding for the Anaconda installer
# /usr/lib/os-release controls the product name shown in the ISO GRUB boot
# menu ("Install RebornOS — Windows 11 Edition") and the Anaconda installer
# window title.  Bazzite ships os-release under /usr/lib; /etc/os-release is
# a symlink to it, so patching the canonical file covers both paths.
# The sed replacements in setup-version-branches.yml update "Windows 11" to
# "Windows 10" or "Windows 7" automatically when creating those branches.
sed -i \
    -e 's/^NAME=.*/NAME="RebornOS"/' \
    -e 's/^PRETTY_NAME=.*/PRETTY_NAME="RebornOS — Windows 11 Edition"/' \
    /usr/lib/os-release

### Anaconda installer product configuration
# /etc/anaconda/product.d/*.conf sets the product name that appears in the
# Anaconda installer GUI title bar and welcome screen, giving the installer
# a Windows-version-specific identity on each branch.
mkdir -p /etc/anaconda/product.d
cat > /etc/anaconda/product.d/rebornos.conf << 'EOF'
[Product]
product_name = RebornOS — Windows 11 Edition
EOF

#### Enable System Unit Files

systemctl enable podman.socket

### Remove GRUB boot menu delay
# Set GRUB_TIMEOUT=0 so the system boots immediately into RebornOS
# without pausing at the menu — matching Windows' default boot behaviour
# where no boot menu is shown to the user.
# GRUB_TIMEOUT_STYLE=hidden suppresses the menu entirely; the countdown
# timer is no longer displayed even if a key is pressed.
_set_grub_option() {
    local key="$1" value="$2"
    if grep -q "^${key}=" /etc/default/grub; then
        sed -i "s|^${key}=.*|${key}=${value}|" /etc/default/grub
    else
        echo "${key}=${value}" >> /etc/default/grub
    fi
}
_set_grub_option GRUB_TIMEOUT 0
_set_grub_option GRUB_TIMEOUT_STYLE "hidden"
unset -f _set_grub_option
