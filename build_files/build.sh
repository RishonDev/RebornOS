#!/bin/bash

set -ouex pipefail

# bootc-image-builder cannot resolve file:// GPG key paths from inherited repos.
normalize_terra_mesa_repo() {
    local terra_key_url="https://repos.fyralabs.com/terra43-mesa/key.asc"
    local terra_key_file="/etc/pki/rpm-gpg/RPM-GPG-KEY-terra43-mesa"
    local repo_files=()

    shopt -s nullglob
    repo_files=(/etc/yum.repos.d/*.repo)
    shopt -u nullglob

    (( ${#repo_files[@]} )) || return 0
    grep -RqsE '(^\[terra-mesa\]$|RPM-GPG-KEY-terra43-mesa)' /etc/yum.repos.d || return 0

    mkdir -p "$(dirname "${terra_key_file}")"
    curl -fsSL "${terra_key_url}" -o "${terra_key_file}"
    rpm --import "${terra_key_file}"

    sed -i \
        -e "/^\[terra-mesa\]$/,/^\[/ s|^gpgkey=.*|gpgkey=${terra_key_url}|" \
        -e "s|file:///etc/pki/rpm-gpg/RPM-GPG-KEY-terra43-mesa|${terra_key_url}|g" \
        "${repo_files[@]}"
}

normalize_terra_mesa_repo
unset -f normalize_terra_mesa_repo

dnf5 install -y tmux

dnf5 install -y \
    wine \
    winetricks \
    cabextract \
    protontricks

dnf5 install -y \
    libreoffice \
    thunderbird \
    vlc

dnf5 install -y \
    liberation-fonts \
    liberation-fonts-common

dnf5 install -y kvantum

curl -L https://github.com/yeyushengfan258/Win11OS-kde/archive/9f021c3e71da7baf59a0614ab858d53b1e455fd5.tar.gz \
    | tar xz -C /tmp
bash /tmp/Win11OS-kde-9f021c3e71da7baf59a0614ab858d53b1e455fd5/install.sh
rm -rf /tmp/Win11OS-kde-9f021c3e71da7baf59a0614ab858d53b1e455fd5

mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/theme.conf << 'EOF'
[Theme]
Current=Win11OS
EOF

mkdir -p /etc/skel/.config
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

mkdir -p /etc/skel/.config/autostart-scripts
cat > /etc/skel/.config/autostart-scripts/apply-look-and-feel.sh << 'EOF'
#!/bin/bash
MARKER="${HOME}/.config/.win11os-look-and-feel-applied"
if [ ! -f "${MARKER}" ]; then
    plasma-apply-lookandfeel --apply com.github.yeyushengfan258.Win11OS-kde
    touch "${MARKER}"
fi
EOF
chmod +x /etc/skel/.config/autostart-scripts/apply-look-and-feel.sh

curl -L https://github.com/vinceliuice/Fluent-icon-theme/archive/refs/tags/2025-08-21.tar.gz \
    | tar xz -C /tmp
bash /tmp/Fluent-icon-theme-2025-08-21/install.sh -d /usr/share/icons
rm -rf /tmp/Fluent-icon-theme-2025-08-21

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

cat > /etc/skel/.local/share/dolphin/view_properties/global/.directory << 'EOF'
[Dolphin]
HiddenFilesShown=false
PreviewsShown=true
SortFoldersFirst=true
SortOrder=0
SortRole=name
ViewMode=1
EOF

dnf5 install -y \
    kcalc \
    spectacle \
    gwenview \
    okular \
    ark \
    kate \
    kolourpaint \
    traceroute

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

rpm --import https://packages.microsoft.com/keys/microsoft.asc
cat > /etc/yum.repos.d/microsoft-powershell.repo << 'EOF'
[microsoft-powershell]
name=Microsoft PowerShell
baseurl=https://packages.microsoft.com/rhel/9.0/prod/
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
[ -L /usr/local ] && rm -f /usr/local
mkdir -p /opt/microsoft/powershell/7
mkdir -p /usr/local/share/man/man1
dnf5 install -y powershell

grep -qxF '/usr/bin/pwsh' /etc/shells || echo '/usr/bin/pwsh' >> /etc/shells
sed -i 's|^SHELL=.*|SHELL=/usr/bin/pwsh|' /etc/default/useradd

mkdir -p /opt/microsoft/powershell/7
cat > /opt/microsoft/powershell/7/profile.ps1 << 'EOF'
Write-Host ""
Write-Host "Windows PowerShell"
Write-Host "Copyright (C) Microsoft Corporation. All rights reserved."
Write-Host ""

function prompt {
    $p = $PWD.Path
    $p = $p -replace [regex]::Escape($HOME), "C:\Users\$env:USER"
    if ($p -notmatch '^C:\\') { $p = 'C:' + $p }
    $p = $p -replace '/', '\'
    "PS $p> "
}

function winget {
    rpm-ostree @args
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Reboot your system to apply the changes" -ForegroundColor Green
    }
}
EOF

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

mkdir -p /etc/bashrc.d
cat > /etc/bashrc.d/windows-shell.bash << 'EOF'
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

alias ver='echo "ReviveOS [$(uname -r)]"'
alias ipconfig='ip addr show'
alias netstat='ss -tulnp'
alias tasklist='ps aux'
alias tracert='traceroute'
alias ping='ping -c 4'
alias where='which'
alias findstr='grep -r'
alias path='echo "$PATH" | tr ":" "\n"'
alias systeminfo='uname -a && echo && cat /etc/os-release'

alias notepad='kate'
alias explorer='dolphin'
alias calc='kcalc'
alias mspaint='kolourpaint'
alias wordpad='libreoffice --writer'
alias store='plasma-discover'
alias winstore='plasma-discover'

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

winget() {
    rpm-ostree "$@"
    local _exit=$?
    if [[ $_exit -eq 0 ]]; then
        printf '\e[32mReboot your system to apply the changes\e[0m\n'
    fi
    return $_exit
}

_win_path() {
    local p
    p="$(pwd)"
    p="${p/#$HOME/C:\\Users\\$USER}"
    [[ "$p" == /* ]] && p="C:${p}"
    printf '%s' "${p//\//\\}"
}
PS1='PS $(_win_path)> '
EOF

sed -i \
    -e 's/^NAME=.*/NAME="ReviveOS"/' \
    -e 's/^PRETTY_NAME=.*/PRETTY_NAME="ReviveOS — Windows 11 Edition"/' \
    /usr/lib/os-release

mkdir -p /etc/anaconda/product.d
cat > /etc/anaconda/product.d/reviveos.conf << 'EOF'
[Product]
product_name = ReviveOS — Windows 11 Edition
EOF

systemctl enable podman.socket

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
