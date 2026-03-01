# RebornOS

RebornOS is a custom [Fedora Atomic](https://fedoraproject.org/atomic-desktops/) / [bootc](https://github.com/bootc-dev/bootc) image built on top of [Bazzite](https://bazzite.gg/) that is designed to look, feel, and work like Windows — while staying fully open-source and Linux-native.

## What's included

### Windows App Compatibility
| Tool | Purpose |
|------|---------|
| **Wine** | Run Windows `.exe` applications directly on Linux |
| **Winetricks** | Install Windows runtimes (DirectX, .NET, Visual C++, etc.) |
| **cabextract** | Extract Windows cabinet/installer archives |

> **Tip:** For a graphical Wine manager, install [Bottles](https://usebottles.com/) from the Flatpak store after first boot:
> ```bash
> flatpak install flathub com.usebottles.bottles
> ```

### Windows-equivalent Linux Apps
| Linux App | Windows Equivalent |
|-----------|--------------------|
| **LibreOffice** (Writer, Calc, Impress) | Microsoft Office (Word, Excel, PowerPoint) |
| **Thunderbird** | Microsoft Outlook |
| **VLC** | Windows Media Player |
| **KCalc** | Calculator |
| **Spectacle** | Snipping Tool |
| **Gwenview** | Photos / image viewer |
| **Okular** | Edge PDF viewer / Windows Reader |
| **Ark** | File Explorer zip support / 7-Zip |
| **Kate** | Notepad / Notepad++ |

### Windows 11 Theming (pre-installed, no manual setup required)
- **[Win11OS-kde](https://github.com/yeyushengfan258/Win11OS-kde)** Kvantum theme is installed system-wide — both `Win11OS-dark` and `Win11OS-light` variants — giving Qt/KDE applications a pixel-accurate Windows 11 appearance.
- **[Fluent icon theme](https://github.com/vinceliuice/Fluent-icon-theme)** is installed system-wide, mirroring the Windows 11 icon design language.
- **Liberation Fonts** (metric-compatible with Arial, Times New Roman, Courier New) are pre-installed so documents from Windows render correctly.

## How to Use

### Switch to this image
From any bootc-based system, run (substitute your GitHub username if you forked this repo):
```bash
sudo bootc switch ghcr.io/<your-github-username>/rebornos:latest
```

### Build it yourself

1. Fork this repository.
2. Enable GitHub Actions for your fork.
3. Create a Cosign key pair and store the private key as the `SIGNING_SECRET` repository secret (see below).
4. Push to `main` — the image will be built and published automatically to GHCR.

#### Creating a Cosign key pair
```bash
COSIGN_PASSWORD="" cosign generate-key-pair
# Then add cosign.key contents as the SIGNING_SECRET Actions secret
# Commit cosign.pub to the repo (never commit cosign.key!)
```

## Base Image

This image is based on [Bazzite](https://bazzite.gg/) (`ghcr.io/ublue-os/bazzite:stable`), which means it already ships with:
- Steam + Proton for Windows game compatibility
- GPU drivers (AMD, Intel, NVIDIA)
- KDE Plasma desktop
- Immutable / atomic updates via bootc

## Community

- [Universal Blue Forums](https://universal-blue.discourse.group/)
- [Universal Blue Discord](https://discord.gg/WEu6BdFEtp)
- [bootc discussion forums](https://github.com/bootc-dev/bootc/discussions)

## Repository Contents

### Containerfile
Defines the container layers for the image. Based on `ghcr.io/ublue-os/bazzite:stable`.

### build_files/build.sh
Installs all packages listed above during the image build.

### .github/workflows/build.yml
Builds the OCI image and publishes it to the GitHub Container Registry (GHCR) on every push to `main`.

## License
[Apache-2.0](./LICENSE)
