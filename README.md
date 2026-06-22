# Ease Mirror™

<p align="center">
  <img src="Resources/ghost-mirror-logo-replica.png" alt="Ghost Mirror — Ease Audio" width="480">
</p>

<p align="center">
  <strong>Your Linux PC. Mirrored on Mac.</strong><br>
  <sub>Ease Audio™ · Apple Silicon · Ghost Cloud</sub>
</p>

<p align="center">
  <a href="#build--run">Build</a> ·
  <a href="#cloud--vps-optional">VPS</a> ·
  <a href="https://github.com/Ease-Audio/ghostcloud">Ghost Cloud</a>
</p>

---

Ease Mirror™ is a native macOS app from **Ease Audio** — Ubuntu on Apple Silicon via Apple's Virtualization framework, with optional Ghost Cloud vault integration.

[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)]()
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-M1%2B-black)]()
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)]()

---

## What it does

| Mode | Description |
|------|-------------|
| **Local Mirror** | Ubuntu ARM64 desktop VM on your Mac — near-native speed |
| **Cloud Mirror** | Connect your VPS Linux desktop over SSH (optional) |
| **Ghost Cloud** | One-click bridge to your encrypted vault in the browser |

---

## Disk footprint (honest)

Nothing heavy lives in this Git repo (~2 MB source). Runtime data is on your Mac:

| Item | Location | Typical size |
|------|----------|--------------|
| **Ubuntu ISO** | `~/Library/Application Support/EaseMirror/ISOs/` | ~3 GB (download once) |
| **VM disk** | same folder, `VMs/*/disk.img` | **32 GB sparse** by default ( grows as you use it) |
| **App build** | `.build/` after compile | ~190 MB — gitignored |

**New default:** 32 GB VM disk (was 64 GB). Enough for Ubuntu desktop + dev tools.

---

## Requirements

- Mac with **Apple Silicon** (M1 or later)
- **macOS 13 Ventura** or later
- **Xcode 15+** or Swift 5.9+ toolchain
- ~4–8 GB RAM for the VM

---

## Build & run

```bash
git clone https://github.com/Ease-Audio/ease-mirror.git
cd ease-mirror
./scripts/build.sh --release
open "Ease Mirror.app"
```

Dev build (unsigned):

```bash
swift build
.build/debug/EaseMirror
```

---

## First run

1. Open **Ease Mirror.app**
2. **Download ISO** (~3 GB Ubuntu 24.04 ARM64)
3. **Start** → install Ubuntu in the window
4. **Mark Installed** → **Start** again (boots from disk)

---

## Cloud / VPS (optional)

Copy the example env file and add your server details:

```bash
mkdir -p ~/.ben_studio
cp config/ease_mirror_cloud.env.example ~/.ben_studio/ease_mirror_cloud.env
chmod 600 ~/.ben_studio/ease_mirror_cloud.env
# edit with your IP, SSH key, Ghost Cloud URL
```

Or configure in the app: **View → Full Mode → VPS Settings**.

---

## CLI

```bash
.build/release/ease-mirror-cli list
.build/release/ease-mirror-cli create "My Mirror" --memory 4 --disk 32
.build/release/ease-mirror-cli download-iso
```

---

## Architecture

```
Ease Mirror.app (SwiftUI)
    └── EaseMirrorCore
            ├── VMStore          — VM definitions on disk
            ├── LinuxVMEngine    — Virtualization.framework
            └── GhostCloudBridge — optional Ghost Cloud scripts
```

---

## Docs

| File | Purpose |
|------|---------|
| **[SETUP.md](./SETUP.md)** | **Full setup & use (start here)** |
| [CHEAP_MODEL.md](./CHEAP_MODEL.md) | Lite tier spec |
| [BLACKBOOK.md](./BLACKBOOK.md) | Engineering notebook |
| [COMMANDS.md](./COMMANDS.md) | Copy-paste command blocks |

---

## License

© **Ease Audio**. Ease Mirror™ is a trademark of Ease Audio.

VM patterns derived from Apple's Virtualization sample (Apple Sample Code License).

---

**Ease Audio** — tools for producers who ship.
