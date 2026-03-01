# RebornOS

RebornOS is a custom [Fedora Atomic](https://fedoraproject.org/atomic-desktops/) / [bootc](https://github.com/bootc-dev/bootc) image built on top of [Bazzite](https://bazzite.gg/) that is designed to look, feel, and work like **Windows 11** — while staying fully open-source and Linux-native.

> **Branch:** `v11` — Windows 11 theme, icons, wallpapers, and apps.  
> Other variants: [`v10`](../../tree/v10) (Windows 10) · [`v7`](../../tree/v7) (Windows 7)

## What's included

### Windows App Compatibility
| Tool | Purpose |
|------|---------|
| **Wine** | Run Windows `.exe` applications directly on Linux |
| **Winetricks** | Install Windows runtimes (DirectX, .NET, Visual C++, etc.) |
| **cabextract** | Extract Windows cabinet/installer archives |
| **Protontricks** | Apply per-game Winetricks overrides inside Proton prefixes |

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
All KDE theme components come from [Win11OS-kde](https://github.com/yeyushengfan258/Win11OS-kde) and are installed system-wide at build time:

| Component | What it themes |
|-----------|---------------|
| **Kvantum theme** (`Win11OS-dark` / `Win11OS-light`) | Qt/KDE application chrome |
| **Aurorae window decoration** | Title bar with Windows 11 close / min / max buttons |
| **Color scheme** | System-wide accent colour and palette |
| **Plasma desktop theme** | Panel, task-switcher, and widget styling |
| **Look-and-feel package** | Panel layout — bottom bar with centered icons (Windows 11 style) |
| **Wallpaper** | Official-style Windows 11 wallpapers |
| **[Fluent icon theme](https://github.com/vinceliuice/Fluent-icon-theme)** | Windows 11 icon design language |
| **Liberation Fonts** | Metric-compatible with Arial, Times New Roman, Courier New |

### Windows Explorer-like File Manager
Dolphin is pre-configured via `/etc/skel/` to match Windows Explorer out of the box:
- **Details view** (Name, Size, Date Modified, Type) — mirrors Explorer's default layout
- **Breadcrumb navigation bar** — matches Explorer's address bar
- **Places panel** on the left — matches Explorer's navigation pane
- **Status bar** at the bottom — shows item count and total size
- **Menu bar hidden** — clean, modern Explorer look

## Downloading an ISO

Every GitHub Release includes a pre-built installer ISO so you can install RebornOS from a USB drive, just like any other Linux distro.

1. Go to the [Releases page](../../releases).
2. Download the `.iso` file attached to the latest release.
3. Flash it to a USB drive (e.g. with [Balena Etcher](https://etcher.balena.io/) or `dd`).
4. Boot from the USB and follow the Anaconda installer.

> **Want to build your own ISO?**  
> Go to **Actions → Publish ISO → Run workflow**, enter the release tag, and the workflow will build and attach the ISO to that release.

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

### .github/workflows/build-disk.yml
Manually-triggered workflow that builds a `qcow2` VM image and an `anaconda-iso` using `bootc-image-builder`. Uploads to job artifacts or S3.

### .github/workflows/release-iso.yml
Automatically builds and attaches an installer ISO to every GitHub Release. Also supports manual triggering via **Actions → Publish ISO → Run workflow**.

## License
[Apache-2.0](./LICENSE)
